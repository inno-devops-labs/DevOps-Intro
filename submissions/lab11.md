# Lab 11 — Reproducible Builds of QuickNotes with Nix

## Environment

- Nix: Determinate Nix 3.22.5 / Nix 2.35.2
- nixpkgs: `nixos-25.11`, revision `b6018f87da91d19d0ab4cf979885689b469cdd41` in [flake.lock](../flake.lock)
- Go from nixpkgs: 1.25.10; host Go 1.22.2 could not run this module's tests
- Architecture: x86_64-linux
- Docker: 29.8.1

## Task 1 — Reproducible Go Build

### Flake configuration

```nix
{
  description = "QuickNotes reproducible build";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

  outputs = { nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      quicknotes = pkgs.buildGoModule {
        pname = "quicknotes";
        version = "0.1.0";
        src = ./app;
        vendorHash = null;
        env.CGO_ENABLED = "0";
        ldflags = [ "-s" "-w" ];
      };
      imageRoot = pkgs.runCommand "quicknotes-image-root" { } ''
        mkdir -p "$out/bin" "$out/tmp"
        ln -s "${quicknotes}/bin/quicknotes" "$out/bin/quicknotes"
        chmod 1777 "$out/tmp"
      '';
      docker = pkgs.dockerTools.buildImage {
        name = "quicknotes-nix";
        tag = "lab11";
        created = "1970-01-01T00:00:01Z";
        copyToRoot = imageRoot;
        config = {
          User = "65532:65532";
          Entrypoint = [ "/bin/quicknotes" ];
          ExposedPorts = { "8080/tcp" = { }; };
          Env = [ "DATA_PATH=/dev/shm/notes.json" "SEED_PATH=/tmp/seed.json" ];
        };
      };
    in {
      packages.${system} = {
        inherit quicknotes docker;
        default = quicknotes;
      };

      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [ go gopls golangci-lint ];
      };
    };
}
```

`buildGoModule` fits this standard Go module and uses the pinned compiler from nixpkgs. `env.CGO_ENABLED = "0"` produces a static, stripped executable; the linker flags are `-s` and `-w`. The default package and `quicknotes` output are identical.

### Vendor hash

The initial build used `pkgs.lib.fakeHash`. It failed with `go: no dependencies to vendor` and instructed `vendorHash = null;`. The current [go.mod](../app/go.mod) has no external module requirements. A fixed hash of a nonexistent vendor tree would be misleading, so this flake uses `null` as required by the pinned builder. If dependencies are added, a real fixed-output vendor hash must be discovered and pinned.

### Local build and runtime

`nix build .#quicknotes` succeeded. Output: `/nix/store/9nn6n320azpj7qx6xhi7c2b67dgw17fv-quicknotes-0.1.0`. `file result/bin/quicknotes` reported `ELF 64-bit LSB executable, x86-64, statically linked, stripped`. The host's 8080 port was occupied, so direct verification used `ADDR=127.0.0.1:18080`: `GET /health` returned `HTTP/1.1 200 OK` and `{"notes":0,"status":"ok"}`.

### Independent build

| Environment | Store hash |
|---|---|
| Host | `sha256:06iryacssvq4m3kdrg2w0nzjy65j8qmd1akj29zrqdrwk9p6vg43` |
| Fresh official `nixos/nix` container | `sha256:06iryacssvq4m3kdrg2w0nzjy65j8qmd1akj29zrqdrwk9p6vg43` |

The hashes match. The container used its own `/nix/store`. Its output path differed when built as `path:/repo`, but the content hash matched. See [independent hashes](../evidence/lab11/02-independent-hashes.txt).

### Development shell

`nix develop --command`: Go 1.25.10, gopls 0.20.0, golangci-lint 2.6.2. `go test ./...` passed inside the shell.

### Design questions

**a) Why can ordinary Go builds differ?** The same Git SHA does not pin the Go toolchain, resolved modules, build flags, environment, or absolute source paths. Build IDs and embedded path information can therefore differ. Timestamps can also enter packaging or generated files. Go can be reproducible when those inputs are controlled; this flake pins the toolchain and dependencies, disables CGO, and builds in a controlled environment.

**b) What does `vendorHash` cover?** It is the fixed-output hash of the vendored Go dependency tree produced by `buildGoModule`, including the resolved module contents. With `null`, the builder skips that fixed-output vendoring step. Here that is correct because there are no dependencies; for a module with dependencies it would remove that integrity check and usually prevent an offline sandbox build.

**c) Why does `flake.lock` matter?** A channel name can advance. The lockfile records an exact nixpkgs revision and content hash, fixing the Go builder and its transitive toolchain. Deleting it before a later build lets Nix resolve a newer revision, changing derivations and possibly outputs.

**d) Why `buildGoModule`?** It is nixpkgs' standard Go module builder and directly supports this app's `go.mod`, `vendorHash`, and linker flags. `buildGoApplication` is associated with the separate gomod2nix workflow, which uses generated dependency metadata. That adds machinery without value for this small module with no external dependencies.

## Task 2 — Deterministic OCI Image

### Build and runtime

`nix build .#docker` uses `pkgs.dockerTools.buildImage` directly; it did not call Docker or BuildKit. The image contains the Task 1 package, fixes `created` to `1970-01-01T00:00:01Z`, sets exec-form `Entrypoint=["/bin/quicknotes"]`, exposes `8080/tcp`, and runs as `65532:65532`. It writes notes to Docker's writable `/dev/shm` tmpfs. `docker load < result` loaded `quicknotes-nix:lab11`. Its container responded `HTTP/1.1 200 OK` at `/health` on host port 28083.

### Independent OCI digest

| Environment | SHA-256 of compressed image tarball |
|---|---|
| Host | `44747a7363fb1ab155ffdcaf368cda6ea93e834d3d90e0fd5e1a821ab5ca0550` |
| Fresh official `nixos/nix` container | `44747a7363fb1ab155ffdcaf368cda6ea93e834d3d90e0fd5e1a821ab5ca0550` |

The digests match when both environments use the Git flake URI. A diagnostic `path:/repo` build differed because it assigned different Nix store paths to the source. The fresh container copied the repository into its own filesystem before the final Git-flake build; it did not share the host store. See [OCI evidence](../evidence/lab11/03-oci-digests.txt).

### Lab 6 comparison

Both `docker build --no-cache` runs completed. Run 1 image ID: `sha256:e02fe2ae07f60827d01ac7cfd136d19fe5500832028eb69158167b09c21dbd1d`; run 2: `sha256:24719dfb0c86240f7c00f8e589befc6e96a2404cc1ec18c6c690f7e0ff4f64c1`. They differ. Both are 14,345,326 bytes by `docker image inspect`; the Nix image is 14,138,797 bytes, 206,529 bytes smaller. The Nix compressed tarball is 5,578,791 bytes. See [Docker comparison](../evidence/lab11/04-docker-comparison.txt).

### Design questions

**e) Why can Docker builds vary?** Dockerfile instructions can read changing base tags, package repositories, file metadata, and build context. Build tools can embed timestamps or paths; layer/config metadata can also change. In these two `--no-cache` runs the image IDs actually differed. Nix fixes the declared inputs and creation time, then produced matching tarball digests under the same Git-flake source semantics.

**f) What can an auditor prove?** A signature identifies who attested to one artifact. An independent reproducible rebuild lets an auditor compare the exact image digest against declared source and pinned inputs, exposing unexpected build-time substitutions. Signatures still establish provenance; the two checks complement each other.

**g) What is the cost?** Nix requires learning its language and store model, consumes disk, and can be harder to debug or integrate with familiar container pipelines. Docker remains common because its tooling, documentation, base images, and team experience are widespread. Reproducibility is valuable here, but requires maintaining the pinned build recipe.

## Bonus — CI-Verified Reproducibility

### Workflow

The [workflow](../.github/workflows/nix-repro.yml) runs on every push and pull request. `build-a` and `build-b` use separate fresh Ubuntu runners, each building `.#docker` and exporting its actual tarball SHA-256 as a job output. `compare` consumes both outputs and fails on a mismatch. All external actions are pinned to exact commits: `actions/checkout` v7.0.1 (`3d3c42e5aac5ba805825da76410c181273ba90b1`) and `DeterminateSystems/nix-installer-action` v23 (`3138316df39ed29be04236d7ffc686fa525866aa`). The initial [green run](https://github.com/SanyaLikeIT/DevOps-Intro/actions/runs/36758932276) passed before the experiment.

### Deliberate RED experiment

- Commit: `460d2ad11f0486d420148992b1a7c25fe0648b06`
- [Run 36759194462](https://github.com/SanyaLikeIT/DevOps-Intro/actions/runs/36759194462): `build-a` and `build-b` succeeded; `compare` failed with `Image tarball digests differ`.
- `build-a`: `4ccc6fe265b5a9ebeb7ff157de3b7c9179bcb5a53d26d8f625f5c147d4727063`
- `build-b`: `c39cab19e396ea4f96c91830c013b1594c291be1f4efdf7fb8252225ad1c290f`

The temporary change set `dockerTools.buildImage.created = "now"` and delayed `build-b` by 90 seconds. The pinned nixpkgs implementation inserts the current time into the image config when `created` is `"now"`; the resulting real tarballs differed. See [RED evidence](../evidence/lab11/05-ci-red.txt).

### Restored GREEN run

- Fix commit: `fa0f9533444766767ae421040b3482969f7d25ab`
- [Run 36759605695](https://github.com/SanyaLikeIT/DevOps-Intro/actions/runs/36759605695): all three jobs succeeded; `compare` logged `Image tarball digests match`.
- `build-a`: `44747a7363fb1ab155ffdcaf368cda6ea93e834d3d90e0fd5e1a821ab5ca0550`
- `build-b`: `44747a7363fb1ab155ffdcaf368cda6ea93e834d3d90e0fd5e1a821ab5ca0550`

The fix restored `created = "1970-01-01T00:00:01Z"` and removed the temporary delay. See [GREEN evidence](../evidence/lab11/06-ci-green.txt).

### Design questions

**h) Why is CI evidence stronger than a laptop rebuild?** A second laptop build can reuse the same local Nix store, cached derivations, filesystem state, and toolchain. Two fresh hosted runners have separate stores and produce public build logs tied to the exact commit. This is stronger, auditable evidence for a reviewer, though it still shares the declared upstream inputs and runner platform.

**i) Why two jobs?** Running twice within one job can return the same cached store output without rebuilding and shares its environment. Separate runners independently realize the derivation and output a digest, so the comparison checks two actual environments.

**j) Where can timestamps leak?** Generated binaries, tar entries, layer metadata, and image config timestamps can alter byte digests. Nix uses `SOURCE_DATE_EPOCH` when normalizing tar metadata, while this flake fixes the image config creation time explicitly. The RED change to `created = "now"` deliberately bypassed that fixed time; the two image configs and tarballs diverged. Restoring the fixed timestamp removed that source of nondeterminism.
