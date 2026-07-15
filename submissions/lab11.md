# Lab 11 — Reproducible Builds of QuickNotes with Nix

## Task 1 — Reproducible Go Build via Nix Flake

### `flake.nix`

```nix
{
  description = "QuickNotes - reproducible Go build";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in
    {
      packages.${system} = {
        quicknotes = pkgs.buildGoModule {
          pname = "quicknotes";
          version = "0.1.0";
          src = ./app;

          vendorHash = null;

          env.CGO_ENABLED = 0;

          ldflags = [ "-s" "-w" ];

          meta = {
            description = "QuickNotes API server";
            mainProgram = "quicknotes";
          };
        };

        default = self.packages.${system}.quicknotes;
      };

      devShells.${system}.default = pkgs.mkShell {
        packages = [
          pkgs.go
          pkgs.gopls
          pkgs.golangci-lint
        ];
      };
    };
}
```

### Build log (clean run)

```
$ nix build .#quicknotes 2>&1 | tail -20
warning: Git tree '/mnt/d/Study/DevOps-Outro' has uncommitted changes
```

### Reproducibility proof — two independent environments

**Environment A** — WSL2 (Ubuntu), local Nix install (Determinate Nix installer), built from local checkout on `feature/lab11`:

```
$ nix-store --query --hash $(readlink result)
sha256:1z6fc78k06d931jpv8r795010mm4k6kizd1nkkdrcv97anr8ma7s
```

**Environment B** — fresh, isolated `nixos/nix` Docker container (no shared Nix store with the host), built directly from the pushed GitHub branch with no local checkout:

```
$ docker run --rm -it nixos/nix bash
bash-5.3# nix --extra-experimental-features "nix-command flakes" \
  build github:darknesod1-netizen/DevOps-Outro/feature/lab11#quicknotes
bash-5.3# nix-store --query --hash $(readlink result)
sha256:1z6fc78k06d931jpv8r795010mm4k6kizd1nkkdrcv97anr8ma7s
```

**Result: identical hashes** — `sha256:1z6fc78k06d931jpv8r795010mm4k6kizd1nkkdrcv97anr8ma7s` in both environments, confirming the build is reproducible across genuinely independent machines/stores.

### Runtime proof

```
$ ADDR=:8081 ./result/bin/quicknotes &
[1] 6819
2026/07/14 20:43:28 quicknotes listening on :8081 (notes loaded: 0)

$ curl -s http://localhost:8081/health
{"notes":0,"status":"ok"}

$ kill %1
2026/07/14 20:43:48 shutting down
```

### Design questions

**a) Why `go build` doesn't produce bit-identical outputs across machines, even from the same Git SHA**

Go embeds build IDs and metadata derived from local file paths and toolchain state into compiled objects; absolute paths on the build machine, ambient environment variables, and small toolchain version differences (a patch-level Go update, differing `GOPATH`/module cache layout) all leak into the binary. If module resolution isn't strictly pinned (e.g. no `go.sum`, or a mutable module proxy), dependency versions can also drift silently between two "identical" builds run days apart. Nix avoids all of this by pinning the exact toolchain via `nixpkgs`, building inside a sandboxed environment with normalized paths, and disallowing network access during the build phase (forcing all inputs to be pre-fetched and content-addressed).

**b) `vendorHash` — what it hashes, and what `vendorHash = null` does**

`vendorHash` is a SHA-256 digest over the contents of the vendored Go module dependencies that Nix fetches based on `go.mod`/`go.sum` (equivalent to running `go mod vendor` and hashing the result). It lets Nix's sandboxed builder verify it fetched exactly the expected dependency tree without needing live network access during the build. Setting `vendorHash = null` tells Nix there is nothing to vendor — valid for QuickNotes since it has zero external dependencies. If a project *did* have dependencies and `vendorHash` were incorrectly set to `null`, the build would fail during the build phase because the sandboxed builder has no network access to fetch the missing packages.

**c) Why `flake.lock` is the single most important file for reproducibility**

`flake.lock` pins `nixpkgs` (and any other flake inputs) to an exact commit revision, not just a branch name. Without it, a URL like `github:NixOS/nixpkgs/nixos-25.05` is a moving reference — the branch tip advances over time, which can silently change the Go toolchain version, compiler flags, or any transitive build tool between two builds run weeks apart. Deleting `flake.lock` before a second build forces Nix to re-resolve `nixpkgs` to whatever the branch currently points to, which is very likely a different commit than the first build used — breaking the reproducibility guarantee entirely. Committing `flake.lock` is what lets anyone who clones the repo get the exact same nixpkgs revision, byte for byte.

**d) `buildGoModule` vs `buildGoApplication` — which and why**

`buildGoModule` is the standard, nixpkgs-native Go builder: no extra flake input required, well documented, and handles `go.mod`/`go.sum` directly via `vendorHash`. `buildGoApplication` comes from the external `gomod2nix` project and offers finer-grained per-dependency caching — useful for large dependency trees where re-vendoring on every `go.mod` change is expensive. For QuickNotes, a zero-dependency, stdlib-only application, there's no dependency tree large enough to benefit from `gomod2nix`'s extra caching machinery, so `buildGoModule` is the simpler and more appropriate choice — it avoids pulling in an additional flake input for no practical gain.

---

## Task 2 — Deterministic OCI Image

*(Not yet completed — to be added.)*

---

## Bonus Task — CI-Verified Reproducibility

*(Not yet completed — to be added.)*
