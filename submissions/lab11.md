# Lab 11 — Reproducible Builds with Nix

Mahmoud Hassan (`selysecr332`)  
**Environment:** Windows 11 + WSL2 (Determinate Nix 3.21.1) + Docker

---

## Task 1 — Reproducible Go build

### flake.nix

See [`flake.nix`](../flake.nix) at repo root (committed with [`flake.lock`](../flake.lock)).

- **nixpkgs:** `nixos-25.05` (Go 1.24.10 — required by `app/go.mod`)
- **Builder:** `buildGoModule` with `vendorHash = null` (no third-party modules), `env.CGO_ENABLED = "0"`, `ldflags = [ "-s" "-w" ]`
- **Outputs:** `packages.x86_64-linux.quicknotes` (and `default`), `devShell` with `go`, `gopls`, `golangci-lint`

### Build log excerpt

```text
$ nix build .#quicknotes
warning: Git tree '...' has uncommitted changes
building '/nix/store/azzrpwws1ahlv0s5rl068rh38svn6z83-quicknotes-0.1.0.drv'...
```

### Reproducibility proof (store hashes)

```text
# WSL (Determinate Nix)
$ nix-store --query --hash result
sha256:0hmzr9k2ylziwb8wxf4mi90lafgxsp9rvr8nkwqxjz7m9wid9wi6

# nixos/nix Docker container (fresh store, same flake.lock)
$ nix build .#quicknotes && nix-store --query --hash result
sha256:0hmzr9k2ylziwb8wxf4mi90lafgxsp9rvr8nkwqxjz7m9wid9wi6
```

### Runtime proof

```text
$ ADDR=:8081 ./result/bin/quicknotes &
2026/07/01 07:33:15 quicknotes listening on :8081 (notes loaded: 0)
$ curl -s localhost:8081/health
{"notes":0,"status":"ok"}
```

> Port 8080 was already in use by local Docker Compose; used `ADDR=:8081` for an isolated proof.

### Design questions (Task 1)

**a) Why doesn't `go build` produce bit-identical outputs on two machines?**

Even from the same Git SHA, `go build` embeds non-reproducible metadata: **build timestamps** in the binary, **module cache** resolution timing, **build IDs** (unless disabled), path prefixes from the build directory, and potentially different **toolchain patch versions**. Two machines rarely share the exact same compiler build environment unless pinned.

**b) `vendorHash` is a SHA over what? What if `vendorHash = null`?**

`vendorHash` is the SHA-256 of the **`vendor/` tree** produced by `go mod vendor` — all module sources Nix will compile against. Setting `vendorHash = null` tells Nix there are **no vendored dependencies** (empty vendor tree). QuickNotes has zero `require` lines in `go.mod`, so `null` is correct; Nix would fail with a hash mismatch if modules were added without updating the hash.

**c) Why is `flake.lock` the most important file for reproducibility?**

It pins **every flake input** (nixpkgs revision, narHash, etc.) to exact commits. Without it, `inputs.nixpkgs` could resolve to a newer nixpkgs on the second build — different Go version, different `stdenv`, different output hash. Deleting `flake.lock` before a second build breaks the guarantee that both environments used identical inputs.

**d) `buildGoModule` vs `buildGoApplication`?**

`buildGoModule` is the mature nixpkgs function: you pass `src`, `vendorHash`, flags; it handles vendor/download/build in the Nix sandbox. `buildGoApplication` is a newer flake-app-oriented wrapper with a more declarative API. For QuickNotes — single module, no external deps, classic layout — **`buildGoModule`** is simpler and well-documented; `buildGoApplication` adds little for this scope.

---

## Task 2 — Deterministic OCI image

### docker output snippet

```nix
mkDocker = pkgs: quicknotes:
  pkgs.dockerTools.buildImage {
    name = "quicknotes";
    tag = "nix";
    copyToRoot = pkgs.buildEnv {
      name = "quicknotes-image-root";
      paths = [
        quicknotes
        (pkgs.linkFarm "quicknotes-seed" [
          { name = "seed.json"; path = ./app/seed.json; }
        ])
      ];
      pathsToLink = [ "/bin" ];
    };
    config = {
      Entrypoint = [ "${quicknotes}/bin/quicknotes" ];
      ExposedPorts = { "8080/tcp" = { }; };
      User = "65534";
    };
  };
```

### Image size comparison

| Image | Size |
|-------|-----:|
| Nix (`nix build .#docker` tarball) | 3.0 MB (compressed; minimal closure) |
| Lab 6 Docker (`docker build ./app`) | 22.7 MB (distroless + binaries) |

Nix image is smaller because `dockerTools.buildImage` packs only the **runtime closure** (static binary + seed.json), not a full distroless base layer stack.

### Nix image digest proof

```text
# WSL
$ sha256sum result
65b95b0f5fbc06c07910a5f6a4049e2f81fd5aa2af7055b94695bf785f9977fe  result

# nixos/nix Docker container
$ nix build .#docker && sha256sum result
65b95b0f5fbc06c07910a5f6a4049e2f81fd5aa2af7055b94695bf785f9977fe  result
```

### Lab 6 non-reproducible comparison

```text
$ docker build --no-cache -t qn-lab6:run1 ./app
$ docker build --no-cache -t qn-lab6:run2 ./app
$ docker images --no-trunc qn-lab6
REPOSITORY   TAG    IMAGE ID                                                                  CREATED         SIZE
qn-lab6      run2   sha256:94788957912b22bae0a1e8aebef80f248d1a06b9c94bc1ed130cfed471b1f6c2   ...             22.7MB
qn-lab6      run1   sha256:2a3abf29ce1d70793a5a4630f109470213c28097594a376bd8066a105bf10047   ...             22.7MB
```

Same Dockerfile + same source → **different image digests** (timestamps/metadata in layers).

### Design questions (Task 2)

**e) What does `docker build` do that introduces non-determinism?**

Layer creation stamps **creation time** metadata; `RUN` steps may capture **timestamps** (`date`, file mtimes); **package mirrors** can resolve slightly different package versions; **build cache** and layer ordering can vary; attestations/manifest lists add unique IDs per build. Even `--no-cache` does not freeze wall-clock time baked into layer metadata.

**f) What can an auditor prove with a reproducible image vs signed-only?**

A **signed** image proves *who published* the artifact. A **reproducible** image proves *what's inside* — anyone can rebuild from source + flake.lock and get the **same digest**. An auditor can verify the binary matches public source without trusting only the publisher's key; supply-chain attacks that alter build output would produce a digest mismatch detectable by independent rebuilders.

**g) Trade-off of Nix reproducibility vs `docker build` default?**

Nix trades **learning curve, slower cold builds, and Nix-specific tooling** for **bit-identical artifacts and pinned inputs**. `docker build` is the default because teams already know Dockerfiles, builds are fast with layer cache, and exact byte-reproducibility is rarely required for dev iteration — but it cannot provide the independent verification Nix enables.

---

## Bonus — CI-verified reproducibility

### Workflow

[`.github/workflows/nix-repro.yml`](../.github/workflows/nix-repro.yml) — two parallel `nix build .#docker` jobs on `ubuntu-24.04`, third job compares `sha256sum` digests (pinned `determinate-nix-action@9adf02b4…` v3.21.1).

### CI evidence

| Run | URL |
|-----|-----|
| Green (digests match) | Fork PR #12 — all 14 checks passed (see `submissions/screenshots/lab_11/2.png`) |
| Red (deliberate mismatch) | <!-- optional: break build-a with SOURCE_DATE_EPOCH: "1" --> |

Screenshots: [`lab_11/1.png`](screenshots/lab_11/1.png) (fork PR), [`lab_11/2.png`](screenshots/lab_11/2.png) (CI green).

**Red-run procedure:** set `SOURCE_DATE_EPOCH: "1"` only on `build-a`, push, confirm `compare` job fails; revert for green.

### Design questions (Bonus)

**h) Laptop vs CI reproducibility?**

Laptop proof is anecdotal — one machine, one network, one cache state. **CI proof** is machine-independent: two fresh GitHub runners with no shared store prove reproducibility holds in a controlled, auditable environment that graders and security teams can re-run on every push.

**i) Why two parallel jobs instead of two builds in one job?**

Parallel jobs run on **independent runners** with separate filesystems and no shared `/nix/store` warm state. A single job running `nix build` twice could reuse store paths, hide environment leaks, or share accidental local mutations; parallel jobs mirror true multi-party rebuild verification.

**j) `SOURCE_DATE_EPOCH` — where would timestamps leak?**

Timestamps leak in **archive metadata** (tar headers in OCI layers), **file mtimes** inside the image rootfs, and sometimes **build-id / linker** output. `dockerTools.buildImage` honors `SOURCE_DATE_EPOCH` to normalize these to a fixed Unix epoch, so two builds produce identical layer bytes; without it, wall-clock time changes the tarball hash.

---

## Lab 11 completion checklist

### Task 1 (4 pts)

- [x] `nix build .#quicknotes` succeeds
- [x] Binary runs; `/health` OK (`ADDR=:8081`)
- [x] Two-environment store hash match
- [x] `flake.lock` committed
- [x] Design questions a–d answered

### Task 2 (4 pts)

- [x] `nix build .#docker`; tarball digest verified
- [x] Two-environment tarball digest match
- [x] Lab 6 digest mismatch documented
- [x] Design questions e–g answered

### Bonus (2 pts)

- [x] CI two-job digest gate — green (14/14 checks on fork PR #12)
- [ ] Red run demo (optional for full bonus)
- [x] Design questions h–j answered

### Submission

- [x] Course PR: https://github.com/inno-devops-labs/DevOps-Intro/pull/1292
- [x] Fork PR: https://github.com/selysecr332/DevOps-Intro/pull/12
- [ ] Moodle URL (submit **course** PR #1292)
