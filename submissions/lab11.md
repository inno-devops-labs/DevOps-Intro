# Lab 11 Submission — Nix and Reproducibility

## Summary

This submission completes Task 1, Task 2, and the Bonus CI task.

Implemented files:

- `flake.nix`
- `flake.lock`
- `.github/workflows/nix-repro.yml`
- `submissions/lab11.md`
- `artifacts/lab11/*` evidence files

## Task 1 — Reproducible Nix package

The repository root contains a Nix flake that builds QuickNotes from `./app`.

Package outputs:

- `packages.x86_64-linux.quicknotes`
- `packages.x86_64-linux.default`

Build command:

    nix build .#quicknotes

Implementation choices:

- I used `pkgs.buildGoModule`.
- `src = ./app`.
- `CGO_ENABLED=0` is set in the derivation.
- `ldflags = [ "-s" "-w" ]` strips the binary.
- `vendorHash = null` because this Go module has no external module dependencies.
- `flake.lock` pins the exact `nixpkgs` revision from `nixos-25.11`.
- The dev shell includes `go`, `gopls`, and `golangci-lint`.

Local build and runtime evidence:

    command: nix build .#quicknotes
    result_path: /nix/store/1ljpx7aw07wwzkaf6ym7abdkjannc59b-quicknotes-0.1.0
    store_hash: sha256:1hv80kblj0zqcz82z0wihvxz63kylgwkqqgv5naykf0ar4f26w8k
    binary_file: result/bin/quicknotes: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), statically linked, stripped
    health_url: http://127.0.0.1:18080/health
    health_response: {"notes":4,"status":"ok"}

Independent fresh clone evidence:

    environment: fresh clone from origin feature/lab11
    clone_path: /tmp/qn-lab11-fresh
    commit: 4ce9bb75403e26ed59502eb869b43dd8a9fc607c
    quicknotes_result_path: /nix/store/1ljpx7aw07wwzkaf6ym7abdkjannc59b-quicknotes-0.1.0
    quicknotes_store_hash: sha256:1hv80kblj0zqcz82z0wihvxz63kylgwkqqgv5naykf0ar4f26w8k
    docker_result_path: /nix/store/bzn1kbyivjlkv2s0mljp0avljq58zzb1-docker-image-quicknotes-nix.tar.gz
    docker_tarball_sha256: c17c1b5a1bea9ce0839f4a3ade27329ef3db586dbad0805f32b14559058ad886

Result:

- Local and fresh-clone QuickNotes store hashes match exactly.
- The built binary is statically linked and stripped.
- The binary served `/health` successfully.

Design answers:

a. The fixed inputs are `flake.lock`, the pinned `nixpkgs` revision, the source tree under `./app`, and the Go module metadata. The output is reproducible because Nix builds from content-addressed, locked inputs rather than mutable host state.

b. `vendorHash = null` is correct here because the module has no external Go dependencies. If dependencies are added later, `vendorHash` should be replaced with the hash Nix reports for the vendored/module dependency set.

c. The binary is more portable because `CGO_ENABLED=0` produces a static Linux executable. The `-s -w` linker flags remove symbol/debug tables, reducing size and avoiding unnecessary metadata.

d. The dev shell provides a repeatable local development environment with Go tooling (`go`, `gopls`, `golangci-lint`) without relying on whatever versions are installed globally on the host.

## Task 2 — Reproducible OCI image with Nix

The flake exposes:

- `packages.x86_64-linux.docker`

Build command:

    nix build .#docker

The image is built with `pkgs.dockerTools.buildImage`, not with the Docker daemon.

Image design:

- Name/tag: `quicknotes-nix:v0.1.0`
- Entrypoint: `[ "/bin/quicknotes" ]`
- User: `65532:65532`
- Exposed port: `8080/tcp`
- Runtime environment:
  - `ADDR=:8080`
  - `DATA_PATH=/tmp/notes.json`
  - `SEED_PATH=/seed.json`
- The image includes the QuickNotes binary and `seed.json`.
- `/tmp` is created with mode `1777` so the nonroot process can write its data file.

Local Nix image evidence:

    command: nix build .#docker
    result_path: /nix/store/bzn1kbyivjlkv2s0mljp0avljq58zzb1-docker-image-quicknotes-nix.tar.gz
    tarball_sha256: c17c1b5a1bea9ce0839f4a3ade27329ef3db586dbad0805f32b14559058ad886
    load_evidence: Loaded image: quicknotes-nix:v0.1.0
    health_response: {"notes":4,"status":"ok"}
    inspect: User=65532:65532 Entrypoint=["/bin/quicknotes"] Env=["ADDR=:8080","DATA_PATH=/tmp/notes.json","SEED_PATH=/seed.json"] ExposedPorts={"8080/tcp":{}}
    image_size:
    REPOSITORY       TAG       IMAGE ID                                                                  CREATED        SIZE
    quicknotes-nix   v0.1.0    sha256:6c0a2c0bd7dd758c58d19f4e5df02a136150163ed1d78ce10394b2a28381c939   56 years ago   8.51MB

Lab 6 Docker comparison evidence:

    source_repo: /home/teeroyce/devops-labs/DevOps-Intro-lab6
    source_app: /home/teeroyce/devops-labs/DevOps-Intro-lab6/app
    source_commit: 01c34d55d5b64ed6ff288226ce2b55d6dab4c9ef
    run1: id=sha256:25a35c50bc88c9f4d2191699e8127d08f95f03e07a707b392076aa613c2e6ddc size=13538083 created=2026-07-03T12:10:14.228018915Z
    run2: id=sha256:cdb60389fc889120915e7fc5c6caa27b8dcbd1c93b35ee1f65e708b74e8193e5 size=13538083 created=2026-07-03T12:12:38.54570022Z
    nix_image: id=sha256:6c0a2c0bd7dd758c58d19f4e5df02a136150163ed1d78ce10394b2a28381c939 size=8506897 created=1970-01-01T00:00:01Z
    nix_tarball_sha256: c17c1b5a1bea9ce0839f4a3ade27329ef3db586dbad0805f32b14559058ad886
    result: Lab 6 Docker run1 and run2 produced different image IDs.

Result:

- The Nix OCI tarball hash matched exactly between the local build and fresh clone build.
- The Nix image loaded with `docker load`.
- The Nix image served `/health` successfully.
- The Nix image was smaller than the Lab 6 Docker image:
  - Nix image: 8,506,897 bytes
  - Lab 6 Docker image: 13,538,083 bytes
- The two Lab 6 Docker builds produced different image IDs:
  - run1: `sha256:25a35c50bc88c9f4d2191699e8127d08f95f03e07a707b392076aa613c2e6ddc`
  - run2: `sha256:cdb60389fc889120915e7fc5c6caa27b8dcbd1c93b35ee1f65e708b74e8193e5`

Design answers:

e. The Nix image is reproducible because the image contents and metadata are produced by Nix from locked inputs. The Docker comparison builds differed because normal Docker builds include mutable build-time metadata such as creation timestamps/layers, even when using the same Dockerfile and source.

f. Running as `65532:65532` avoids running the service as root in the container. Because the application writes notes data at runtime, the image explicitly uses `/tmp/notes.json` and creates `/tmp` with writable sticky permissions.

g. The Nix image is smaller because it contains only the built static binary, seed file, and minimal runtime filesystem needed by the service. The Lab 6 image includes the distroless base and healthcheck binary, so it is larger.

## Bonus CI — Reproducibility gate

Workflow file:

- `.github/workflows/nix-repro.yml`

Trigger:

- `push` on all branches
- `pull_request`

Pinned action SHAs:

    actions/checkout@34e114876b0b11c390a56381ad16ebd13914f8d5
    actions/upload-artifact@ea165f8d65b6e75b540449e92b4886f43607fa02
    actions/download-artifact@d3f86a106a0bac45b974a628896c90dbdf5c8093
    DeterminateSystems/nix-installer-action@a7ad9c4f0c65208097f4d34f3cfa1913b80cce5c

Workflow behavior:

- Matrix job `build` runs two independent GitHub-hosted builds: replica `a` and replica `b`.
- Each job installs Nix, builds `.#docker`, computes `sha256sum result`, and uploads the digest artifact.
- Job `compare-digests` downloads both artifacts and fails unless the two digests match.

Red run evidence:

    red_run_url: https://github.com/tivdzualubem/DevOps-Intro/actions/runs/28660572075
    red_head_sha: 195f11979703922a71d9791a50ec17d25b2fe641
    red_result: failure caused by deliberately mismatched digest in replica a

Green run evidence:

    green_run_url: https://github.com/tivdzualubem/DevOps-Intro/actions/runs/28661327106
    green_head_sha: eacacb28d039f19307dbcf7791ff2105515f2292
    green_result: success; both matrix jobs produced the same Nix docker tarball digest and uploaded build artifacts

Design answers:

h. I pinned GitHub Actions by full 40-character commit SHA so CI does not silently change when action tags move.

i. The red run deliberately changed the digest reported by replica `a`. The compare job failed, proving that the workflow catches digest mismatches.

j. The green run removed the deliberate mismatch. Both matrix jobs built the Nix Docker image, uploaded build artifacts, and produced the same digest, so the compare job passed.
