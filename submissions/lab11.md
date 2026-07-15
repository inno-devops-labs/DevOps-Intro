# Lab 11 (Bonus): Reproducible Builds of QuickNotes with Nix

Verified with the `nixos/nix` container. "Two independent environments" = two separate
`docker run --rm` invocations with **no shared `/nix` store** — each a cold, independent build.

## Task 1: Reproducible Go Build via Nix Flake

### `flake.nix` (repo root)

```nix
{
  description = "QuickNotes — reproducible builds with Nix (DevOps-Intro Lab 11)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f (import nixpkgs { inherit system; }));
    in
    {
      packages = forAllSystems (pkgs:
        let
          quicknotes = pkgs.buildGoModule {
            pname = "quicknotes";
            version = "0.1.0";
            src = ./app;
            vendorHash = null;
            CGO_ENABLED = 0;
            ldflags = [ "-s" "-w" ];
            subPackages = [ "." ];
          };

          docker = pkgs.dockerTools.buildImage {
            name = "quicknotes";
            tag = "0.1.0";
            copyToRoot = [ quicknotes ];
            extraCommands = ''
              cp ${./app/seed.json} seed.json
              mkdir -p data && chmod 0777 data
            '';
            config = {
              Entrypoint = [ "/bin/quicknotes" ];
              ExposedPorts = { "8080/tcp" = { }; };
              User = "65532:65532";
              Env = [
                "ADDR=:8080"
                "DATA_PATH=/data/notes.json"
                "SEED_PATH=/seed.json"
              ];
            };
          };
        in
        {
          inherit quicknotes docker;
          default = quicknotes;
        });

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = [ pkgs.go pkgs.gopls pkgs.golangci-lint ];
        };
      });
    };
}
```

`flake.lock` is committed at the repo root. It pins nixpkgs to:

```
rev = ac62194c3917d5f474c1a844b6fd6da2db95077d   (nixos-25.05)
narHash = sha256-16KkgfdYqjaeRGBaYsNrhPRRENs0qzkQVUooNHtoy2w=
```

- **nixpkgs `nixos-25.05`, not `24.11`:** `app/go.mod` requires `go 1.24`; the 24.11 channel ships Go 1.23. 25.05 ships Go **1.24.10**, so it satisfies the module.
- **`buildGoModule`, not `buildGoApplication`:** see design (d).
- **`vendorHash = null`:** QuickNotes is pure standard library (empty `require`, no `go.sum`), so there is nothing to vendor. See design (b).
- `buildGoModule` adds `-trimpath` automatically; `ldflags = [ "-s" "-w" ]` and `CGO_ENABLED = 0` carry Lab 6's static/stripped discipline.

### Build log excerpt

```text
$ nix build .#quicknotes -L
quicknotes> Building subPackage .
quicknotes> stripping (with command strip and flags -S -p) in /nix/store/...-quicknotes-0.1.0/bin
$ file ./result/bin/quicknotes
./result/bin/quicknotes: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), statically linked, stripped
```

### Two independent store hashes — identical

```text
# Environment A (fresh container, cold /nix store)
$ nix build .#quicknotes && nix-store --query --hash "$(readlink -f result)"
/nix/store/p21vj1wjrqlp5x024phnrv7jfq6dkyhs-quicknotes-0.1.0
sha256:0zwp1zagzqag210qkfvplnpyzypfg86lz5kzckj1xp9xm03x6bib

# Environment B (separate fresh container, cold /nix store, same committed flake.lock)
/nix/store/p21vj1wjrqlp5x024phnrv7jfq6dkyhs-quicknotes-0.1.0
sha256:0zwp1zagzqag210qkfvplnpyzypfg86lz5kzckj1xp9xm03x6bib
```

Identical store path **and** NAR hash.

### It runs — `/health`

```text
$ SEED_PATH=app/seed.json DATA_PATH=/tmp/qn/notes.json ./result/bin/quicknotes &
quicknotes listening on :8080 (notes loaded: 4)
$ curl -s http://127.0.0.1:8080/health
{"notes":4,"status":"ok"}
```

### Design questions

**a) Why does `go build` not produce bit-identical output on two machines from the same Git SHA?**
Vanilla `go build` bakes in machine-specific state: absolute module-cache/GOPATH paths embedded in the binary, a build ID derived from the toolchain + environment, and embedded VCS/build metadata. A different Go patch version or an unpinned dependency resolving to a newer version also changes the code. Nix removes all of these — `-trimpath` strips paths, the Go toolchain is pinned by the nixpkgs revision, dependencies are pinned by `vendorHash`, and the build runs in a sandbox with normalized environment variables.

**b) `vendorHash` is a SHA over what? What happens with `vendorHash = null`?**
It is the fixed-output hash of the whole vendored dependency tree that `buildGoModule` fetches (every module dependency's source), pinning them byte-for-byte. `vendorHash = null` tells `buildGoModule` the module has **no** dependencies to vendor, so it skips the vendor/`goModules` derivation entirely. For QuickNotes that is correct (stdlib only). If a module *did* have dependencies and you set `null`, the build fails because no dependencies are fetched.

**c) Why is `flake.lock` the single most important file for reproducibility? What if you delete it before the second build?**
It pins every input — here nixpkgs — to an exact commit + `narHash`, which transitively pins the Go compiler, `tzdata`, and everything else, so the same inputs produce the same output hash. Delete it before the second build and `nix build` re-resolves the `nixos-25.05` *branch* to whatever it points at **now** (a later commit) → different toolchain/deps → a different hash. This is the usual cause of "different hashes on two machines."

**d) `buildGoModule` vs `buildGoApplication` — which for QuickNotes and why?**
`buildGoModule` (nixpkgs standard) fetches all dependencies as one fixed-output derivation keyed by `vendorHash`; simple and needs no extra flake input. `buildGoApplication` (from `gomod2nix`) builds each dependency as its own derivation from a generated `gomod2nix.toml`, giving finer-grained caching but requiring an extra tool, a generated lockfile, and an extra flake input. QuickNotes has **zero** dependencies, so per-dependency derivations buy nothing — `buildGoModule` with `vendorHash = null` is the simpler, fewer-moving-parts choice.

---

## Task 2: Deterministic OCI Image

### Extended `flake.nix` snippet

```nix
docker = pkgs.dockerTools.buildImage {
  name = "quicknotes";
  tag = "0.1.0";
  copyToRoot = [ quicknotes ];
  extraCommands = ''
    cp ${./app/seed.json} seed.json
    mkdir -p data && chmod 0777 data
  '';
  config = {
    Entrypoint = [ "/bin/quicknotes" ];
    ExposedPorts = { "8080/tcp" = { }; };
    User = "65532:65532";
    Env = [ "ADDR=:8080" "DATA_PATH=/data/notes.json" "SEED_PATH=/seed.json" ];
  };
};
```

Built with **no Docker** (pure Nix). `User = "65532:65532"` (nonroot, matching Lab 6's distroless `nonroot`); the data dir is `chmod 0777` so the unprivileged user can persist notes — Nix cannot `chown` in the unprivileged build sandbox, so a world-writable dedicated dir is the deterministic equivalent.

### Loadable + runs as nonroot

```text
$ nix build .#docker
$ docker load -i result
Loaded image: quicknotes:0.1.0
$ docker run -d -p 18080:8080 quicknotes:0.1.0
$ docker inspect ... --format 'User={{.Config.User}} Entrypoint={{json .Config.Entrypoint}} Exposed={{json .Config.ExposedPorts}}'
User=65532:65532 Entrypoint=["/bin/quicknotes"] Exposed={"8080/tcp":{}}
$ curl -s :18080/health
{"notes":4,"status":"ok"}
$ curl -s -X POST :18080/notes -d '{"title":"repro","body":"nix"}' -H 'content-type: application/json'
{"id":5,"title":"repro","body":"nix","created_at":"..."}     # nonroot write succeeds
```

### Two independent image digests — identical

```text
# Environment A                                                # Environment B (separate cold container)
$ nix build .#docker && sha256sum result                       $ nix build .#docker && sha256sum result
c67e22c09aadd0545b98cc10b8d198ee5ee435e46d4e2b728e93447e3e5da10b  result
c67e22c09aadd0545b98cc10b8d198ee5ee435e46d4e2b728e93447e3e5da10b  result   ← identical
```

### Comparison with Lab 6's non-reproducible Docker build

```text
$ docker build --no-cache -t qn-lab6:run1 ./app
$ docker build --no-cache -t qn-lab6:run2 ./app
$ docker images --no-trunc qn-lab6
run1  sha256:c61326b3675d4ba594e7df8f7ee56ff8e48e8eb0c263c55df6c2dfd791fc3de9
run2  sha256:039a991661e5116b35d160ca7d7f853da607d36955c6811160b939e3c52ed1ab   ← differ
```

The two Lab 6 image IDs differ. The cause is visible in the config `created` field and the layer file mtimes:

| | `created` timestamp | binary mtime in layer |
|---|---|---|
| Nix `.#docker` | `1970-01-01T00:00:01Z` (fixed) | `1980-01-01` (normalized) |
| Lab 6 run1 | `2026-07-15T20:50:06.090Z` | build wall-clock |
| Lab 6 run2 | `2026-07-15T20:50:16.082Z` | build wall-clock |

**Image-size comparison**

| Artifact | Size | Notes |
|---|---:|---|
| Nix binary | 6,338,096 B (6.3 MB) | Go 1.24.10, static, stripped |
| Lab 6 binary | 6,348,984 B (6.3 MB) | Go 1.24 (`golang:1.24-alpine`), static, stripped |
| Nix image (uncompressed) | 22.4 MB | binary + full runtime closure |
| Nix image tarball (gzip, hashed) | 3.3 MB | |
| Lab 6 image (uncompressed) | 15.2 MB | distroless `static-debian12:nonroot` base |

Both toolchains are Go 1.24, so the binaries come out within ~11 KB of each other (Nix marginally *smaller*). The Nix **image** is nonetheless larger because it contains the complete runtime closure QuickNotes references — `tzdata-2025b`, `iana-etc`, `mailcap` (pulled in by Go's `time`/`net`) — whereas distroless ships a curated subset. That is the honest closure: every path the binary can touch at runtime is present and pinned, which is exactly what makes the digest reproducible.

### Design questions

**e) `dockerTools.buildImage` is deterministic — what does `docker build` do that isn't?**
`docker build` stamps wall-clock time into the image config `created` field (shown: run1 `20:50:06` vs run2 `20:50:16`) and into every layer tar entry's mtime, and unpinned `RUN apt-get`/`go mod download`/`FROM tag` steps pull whatever the mirror serves at build time. `dockerTools.buildImage` normalizes all of it: `created` defaults to the Unix epoch, tar mtimes are fixed, no network during the build, and every input is pinned by store hash — so the tar is byte-identical and the sha256 matches.

**f) For a security auditor, what does a reproducible image prove that a signed-but-non-reproducible one cannot?**
A signature proves *who* produced a blob and that it is unchanged since signing — provenance and integrity, but only of that opaque blob. A reproducible image proves the *content matches the source*: anyone can rebuild from the pinned source and obtain the identical digest, so no code was injected beyond what is in the source, and you no longer have to trust the build machine or CI. Signing says "I built this"; reproducibility lets a third party say "and I rebuilt the same thing from source." Together they give provenance **and** verifiable content (the xz-utils backdoor would have shown up as a digest divergence).

**g) What is the trade-off, and why is `docker build` still the default?**
Nix costs a steep learning curve, dense error messages, slow cold builds, a smaller pool of expertise, rougher edges in some ecosystems/macOS, and sometimes larger images (the full closure — our 22.4 MB vs 15.2 MB). `docker build` stays the default because it is ubiquitous, approachable, has enormous ecosystem/registry tooling, and is "good enough" for teams that do not yet have a hard supply-chain/audit requirement. Reproducibility becomes worth the cost only when you must *prove* content, not just ship it.

---

## Bonus Task: CI-Verified Reproducibility

### Workflow — `.github/workflows/nix-repro.yml`

```yaml
name: nix-repro

on:
  push:
  pull_request:
  workflow_dispatch:
    inputs:
      break_repro:
        description: Tamper build-a to prove the gate catches divergence
        type: boolean
        default: false

permissions:
  contents: read

jobs:
  build-a:
    runs-on: ubuntu-24.04
    outputs:
      digest: ${{ steps.digest.outputs.value }}
    steps:
      - uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11
      - if: ${{ github.event.inputs.break_repro == 'true' }}
        run: echo "divergence" >> app/seed.json
      - uses: DeterminateSystems/nix-installer-action@ef8a148080ab6020fd15196c2084a2eea5ff2d25
      - run: nix build .#docker
      - id: digest
        run: echo "value=$(sha256sum result | awk '{print $1}')" >> "$GITHUB_OUTPUT"

  build-b:
    runs-on: ubuntu-24.04
    outputs:
      digest: ${{ steps.digest.outputs.value }}
    steps:
      - uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11
      - uses: DeterminateSystems/nix-installer-action@ef8a148080ab6020fd15196c2084a2eea5ff2d25
      - run: nix build .#docker
      - id: digest
        run: echo "value=$(sha256sum result | awk '{print $1}')" >> "$GITHUB_OUTPUT"

  compare:
    needs: [build-a, build-b]
    runs-on: ubuntu-24.04
    steps:
      - name: Assert identical digests
        run: |
          a='${{ needs.build-a.outputs.digest }}'
          b='${{ needs.build-b.outputs.digest }}'
          echo "build-a: $a"
          echo "build-b: $b"
          if [ -z "$a" ] || [ "$a" != "$b" ]; then
            echo "::error::Nix image digests differ — reproducibility broken"
            exit 1
          fi
          echo "reproducible: both runners produced $a"
```

Two parallel jobs on separate fresh runners, each SHA-pinned (`nix-installer-action` v22 = `ef8a148…`, `checkout` = `b4ffde6…`); a third `compare` job fails the workflow unless both digests match. `workflow_dispatch` with `break_repro=true` injects a divergence into `build-a` on demand for the red run.

### Gate behaviour — verified locally against the exact `compare` logic

**Green** (two independent cold builds, untampered):

```text
build-a: c67e22c09aadd0545b98cc10b8d198ee5ee435e46d4e2b728e93447e3e5da10b
build-b: c67e22c09aadd0545b98cc10b8d198ee5ee435e46d4e2b728e93447e3e5da10b
reproducible: both runners produced c67e22c0...   -> exit 0 (PASS)
```

**Red** (`break_repro` → `echo "divergence" >> app/seed.json` in build-a):

```text
build-a: a4c9219ea5a039eb43e43eaac3d1a3552a032d7e38e785c738e59b9070cdb98e
build-b: c67e22c09aadd0545b98cc10b8d198ee5ee435e46d4e2b728e93447e3e5da10b
::error::Nix image digests differ — reproducibility broken   -> exit 1 (FAIL)
```

> CI run URLs (green + `break_repro` red) to be attached after `git push` — the workflow, its SHA pins, and the gate logic above are verified locally against the identical `compare` script.

### Design questions

**h) What makes "reproducible in CI" load-bearing for an auditor, versus "reproducible on my laptop"?**
A laptop carries hidden state — a warm `/nix` store, local config, ambient env, uncommitted files — so a build can *look* reproducible only because it is reusing cached output instead of rebuilding, and no auditor can independently check it. CI runs on fresh, ephemeral, publicly-defined runners from a clean checkout, so the entire recipe lives in the repo and is re-executed by a third party on infrastructure you do not control, on every push. That turns the claim from anecdote into evidence.

**i) Why two parallel jobs instead of one job that runs `nix build` twice?**
One job runs both builds on the *same* runner and the *same* `/nix` store — the second build usually just returns the first's cached path without truly rebuilding, so it proves nothing, and any host-specific determinism (arch, timezone/locale leakage, a poisoned cache) is shared by both and cancels out. Two parallel jobs are two independent fresh runners with cold stores, so matching digests mean the *recipe* — not shared machine state — produced the result. (Also: a 2-cell matrix cannot expose two distinct `outputs:` — they collide — which is why the workflow uses two explicit jobs.)

**j) `SOURCE_DATE_EPOCH` — where would the timestamp normally leak in, and how does `dockerTools.buildImage` handle it?**
The timestamp leaks into two places: the image config `created` field, and every layer tar entry's mtime. `dockerTools.buildImage` neutralizes both, but differently:

- `created` is hard-pinned to a fixed constant, default `"1970-01-01T00:00:01Z"` (independent of `SOURCE_DATE_EPOCH`) — verified in `pkgs/build-support/docker/default.nix`.
- Layer tar mtimes **are** set from `SOURCE_DATE_EPOCH` — every `tar` call uses `--mtime="@$SOURCE_DATE_EPOCH"`. That variable is not the ambient shell one: nixpkgs `stdenv` fixes `SOURCE_DATE_EPOCH=315532800` inside the build (`= 1980-01-01T00:00:00Z`, which is exactly the `1980-01-01` mtime in the size-comparison table above).

So changing `SOURCE_DATE_EPOCH` in the CI runner's shell is a no-op on the digest — not because `buildImage` ignores it, but because a sandboxed `nix build` scrubs ambient env vars and `stdenv` re-pins `SOURCE_DATE_EPOCH` inside the derivation, so the outer value never reaches the build. That is why the red run required tampering an actual build input (`app/seed.json`) rather than resetting `SOURCE_DATE_EPOCH`. (A live `created` is only possible by explicitly passing `created = "now"`, which deliberately makes the image non-reproducible.)
