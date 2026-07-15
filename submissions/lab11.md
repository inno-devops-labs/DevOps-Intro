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

`flake.lock` committed alongside (pins `nixpkgs` to `ac62194`, `nixos-25.05`).

### Build log

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

### Extended `flake.nix` (docker output)

```nix
        docker = pkgs.dockerTools.buildImage {
          name = "quicknotes";
          tag = "0.1.0";
          created = "1970-01-01T00:00:01Z";

          copyToRoot = pkgs.buildEnv {
            name = "image-root";
            paths = [ self.packages.${system}.quicknotes ];
            pathsToLink = [ "/bin" ];
          };

          config = {
            Entrypoint = [ "/bin/quicknotes" ];
            ExposedPorts = {
              "8080/tcp" = { };
            };
            User = "65532:65532";
          };
        };
```

### Image size comparison

```
ghcr.io/darknesod1-netizen/devops-outro/quicknotes:0.1.0   14.8MB   3.34MB
quicknotes:0.1.0 (Nix-built)                                21.4MB   9.49MB
quicknotes:lab6 (Docker-built)                              14.8MB   3.32MB
```

Nix-built image is larger — `dockerTools.buildImage`'s closure pulls in more of the Nix store dependency graph than the hand-tuned distroless Dockerfile from Lab 6.

### Reproducibility proof — two independent Nix builds

```
Environment A (fresh nixos/nix container, built from GitHub):
80ccdad1b00695e9ae3609c70452a2bb4835346dd8d0f1a7b3e37df5569d0118

Environment B (separate fresh nixos/nix container, built from GitHub):
80ccdad1b00695e9ae3609c70452a2bb4835346dd8d0f1a7b3e37df5569d0118
```

Identical.

### Lab 6 Docker build — non-determinism proof

```
$ docker build --no-cache -t qn-lab6:run1 ./app
$ docker build --no-cache -t qn-lab6:run2 ./app
$ docker images --no-trunc | grep qn-lab6
qn-lab6   run2   sha256:4d1595733d095e2f595f86d594cc5f66490216e5a0c0476d4e6a3dce4242b39c
qn-lab6   run1   sha256:ad17d82a0b3b3f7a646a4081a78be625f435ac202f3fcf5e70fd3b538445f1f9
```

Different digests from identical Dockerfile + source — confirms Docker build is not reproducible.

### Design questions

**e) What makes `docker build` non-deterministic:** each layer embeds a creation timestamp stamped with the actual wall-clock build time; package installs can also pull different transitive versions if upstream repos moved since the last build, even with a pinned base image.

**f) What reproducibility proves that signing alone can't:** a signature proves who produced an artifact and that it wasn't tampered with in transit, but says nothing about what's inside. A reproducible build lets a third party rebuild from source independently and verify the published artifact matches exactly — proving the build pipeline itself wasn't compromised. Signing requires trusting the builder; reproducibility lets you verify them.

**g) Trade-off of Nix reproducibility, and why `docker build` stays the default:** steeper learning curve, unfamiliar mental model (functional, content-addressed store), and larger images by default (see size comparison above). `docker build` remains the default because it's what teams already know and it integrates with existing CI/CD without new tooling — pinned base images + lockfiles are "good enough" reproducibility for most teams' threat models. Full bit-for-bit reproducibility matters most for high-assurance software supply chains, not typical app deployments.

---