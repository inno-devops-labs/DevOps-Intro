# Lab 11 — Reproducible Builds of QuickNotes with Nix

## Repository information

- Branch: `feature/lab11`
- Fork: https://github.com/giselesikeh/DevOps-Intro
- Course repo: https://github.com/inno-devops-labs/DevOps-Intro

---

## Task 1 — Reproducible Go Build via Nix Flake

### `flake.nix`

```nix
{
  description = "Reproducible QuickNotes build with Nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in {
      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          go = pkgs.go_1_24;
          buildGoModule = pkgs.buildGoModule.override { inherit go; };
        in rec {
          quicknotes = buildGoModule {
            pname = "quicknotes";
            version = "lab11";

            src = ./app;

            env.CGO_ENABLED = "0";

            # QuickNotes currently has no external Go module dependencies.
            # buildGoModule requires vendorHash = null when the vendored module tree is empty.
            vendorHash = null;

            ldflags = [ "-s" "-w" ];

            subPackages = [ "." ];

            meta = {
              description = "QuickNotes Go application";
              mainProgram = "quicknotes";
            };
          };

          default = quicknotes;
        });

      devShells = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in {
          default = pkgs.mkShell {
            packages = [
              pkgs.go_1_24
              pkgs.gopls
              pkgs.golangci-lint
            ];
          };
        });
    };
}
```

`flake.lock` is committed with the flake. It pins the exact nixpkgs revision used by the build.

### Build log excerpt

Command used:

```bash
nix --extra-experimental-features "nix-command flakes" build .#quicknotes
```

Log excerpt:

```text
building '/nix/store/351iq6bckyn7ax1f9xnimf4fda9i1iwz-quicknotes-lab11.drv'...
store path A:
/nix/store/cbkx1sip5br685mxiplxfbxyggc4lr8f-quicknotes-lab11
store hash A:
sha256:1z6fc78k06d931jpv8r795010mm4k6kizd1nkkdrcv97anr8ma7s
```

### Two independent build hashes

Environment A:

```text
store path A:
/nix/store/cbkx1sip5br685mxiplxfbxyggc4lr8f-quicknotes-lab11
store hash A:
sha256:1z6fc78k06d931jpv8r795010mm4k6kizd1nkkdrcv97anr8ma7s
```

Environment B:

```text
store path B:
/nix/store/cbkx1sip5br685mxiplxfbxyggc4lr8f-quicknotes-lab11
store hash B:
sha256:1z6fc78k06d931jpv8r795010mm4k6kizd1nkkdrcv97anr8ma7s
```

The two independent builds produced the same store path and the same Nix store hash.

### Runtime proof

The Nix-built QuickNotes binary was started from `./result/bin/quicknotes` inside a fresh `nixos/nix` container and exposed on host port `18080`.

Command used:

```bash
curl -s http://localhost:18080/health
```

Output:

```json
{"notes":0,"status":"ok"}
```

Container log excerpt:

```text
building '/nix/store/351iq6bckyn7ax1f9xnimf4fda9i1iwz-quicknotes-lab11.drv'...
2026/07/01 21:06:44 quicknotes listening on :8080 (notes loaded: 0)
```

### Design questions

#### a) Why does `go build` not produce bit-identical outputs on two machines, even from the same Git SHA?

A plain `go build` can depend on details outside the source tree: the local Go toolchain version, module cache contents, build paths, timestamps, environment variables, and embedded build IDs. Even when the Git SHA is the same, two machines may resolve or cache dependencies differently, use different compiler versions, or embed different metadata. Nix removes these differences by pinning the toolchain, dependencies, build inputs, and environment.

#### b) `vendorHash` is a SHA over what, exactly? What happens if you set `vendorHash = null;`?

For `buildGoModule`, `vendorHash` is the hash of the fixed-output derivation containing the vendored Go module dependency tree. It verifies that the downloaded Go module dependencies are exactly what the Nix expression expects.

In this QuickNotes project, `go.mod` currently has no external module dependencies, so the vendored module tree is empty. The first Nix build reported:

```text
go: no dependencies to vendor
vendor folder is empty, please set 'vendorHash = null;' in your expression
```

So for this project, `vendorHash = null;` is correct. If external dependencies are added later, `vendorHash` must be changed to the real dependency hash.

#### c) `flake.lock` pins nixpkgs. Why is this the single most important file for reproducibility? What happens if you delete it before the second build?

`flake.lock` records the exact nixpkgs revision and content hash used by the build. This is critical because nixpkgs controls the Go compiler version, `buildGoModule`, Docker/Nix tooling, libc, shell tools, and every other package input.

If `flake.lock` is deleted before the second build, Nix may resolve `nixos-25.05` again to a newer revision. The same `flake.nix` could then build with different package definitions or tool versions, which can change the output hash and break reproducibility.

#### d) `buildGoModule` vs `buildGoApplication` — what is the difference? Which would you pick for QuickNotes and why?

`buildGoModule` is the standard nixpkgs builder for Go projects that use Go modules. It vendors or verifies module dependencies with `vendorHash`, builds the selected package, and integrates cleanly with normal Go module projects.

`buildGoApplication` is commonly associated with the `gomod2nix` workflow, where Go dependencies are translated into Nix expressions ahead of time. That can provide fine-grained dependency control, but it adds extra generated files and workflow complexity.

For QuickNotes, I picked `buildGoModule` because the app is a small Go module in `app/`, has no external dependencies right now, and the lab explicitly allows `buildGoModule`. It gives a simple reproducible build while keeping the flake easy to read and maintain.

---

## Task 2 — Deterministic OCI Image

### Extended `flake.nix` Docker image output

The flake was extended with a `docker` package using `pkgs.dockerTools.buildImage`. The image is built by Nix only, without using Docker during image construction.

```nix
docker = pkgs.dockerTools.buildImage {
  name = "quicknotes-nix";
  tag = "lab11";

  # Fixed timestamp for deterministic image metadata.
  created = "1970-01-01T00:00:01Z";

  copyToRoot = pkgs.buildEnv {
    name = "quicknotes-image-root";
    paths = [ quicknotes ];
    pathsToLink = [ "/bin" ];
  };

  # QuickNotes writes runtime data relative to the working directory.
  # /tmp is writable for the numeric nonroot user.
  extraCommands = ''
    mkdir -p tmp
    chmod 1777 tmp
  '';

  config = {
    Entrypoint = [ "/bin/quicknotes" ];
    ExposedPorts = {
      "8080/tcp" = {};
    };
    User = "65532:65532";
    WorkingDir = "/tmp";
  };
};
```

This satisfies the image requirements:

```text
User=65532:65532 Entrypoint=["/bin/quicknotes"] ExposedPorts={"8080/tcp":{}} Size=9493418
```

### Nix-built OCI image reproducibility

Command used:

```bash
nix --extra-experimental-features "nix-command flakes" build .#docker
sha256sum result
```

Environment A:

```text
image tar path A:
/nix/store/aphx9492z7mm6580xrlp94h1rm1701hn-docker-image-quicknotes-nix.tar.gz
sha256 A:
22a98074d6b89b757810ef7411ee52962991d2189c9b2e24c6fa912ac16c2c16  result
```

Environment B:

```text
image tar path B:
/nix/store/aphx9492z7mm6580xrlp94h1rm1701hn-docker-image-quicknotes-nix.tar.gz
sha256 B:
22a98074d6b89b757810ef7411ee52962991d2189c9b2e24c6fa912ac16c2c16  result
```

The two independent Nix image builds produced the same image tarball path and the same SHA-256 digest:

```text
22a98074d6b89b757810ef7411ee52962991d2189c9b2e24c6fa912ac16c2c16
```

### Loading and running the Nix-built OCI image

The image was loaded into Docker:

```bash
docker load -i quicknotes-nix-image.tar
```

Output:

```text
Loaded image: quicknotes-nix:lab11
```

The image config was inspected:

```text
User=65532:65532 Entrypoint=["/bin/quicknotes"] ExposedPorts={"8080/tcp":{}} Size=9493418
```

The image was run on host port `18081`:

```bash
docker run -d --name quicknotes-nix-oci-test -p 18081:8080 quicknotes-nix:lab11
curl -s http://localhost:18081/health
```

Output:

```json
{"notes":0,"status":"ok"}
```

Container log excerpt:

```text
2026/07/01 21:25:28 quicknotes listening on :8080 (notes loaded: 0)
```

### Image-size comparison

Nix-built image:

```text
nix image ID=sha256:a3ab6ffc61834e25452d324ce16c6ff0a2711704bb18a05489cc571c99b6aac2 Size=9493418 Created=1970-01-01T00:00:01Z User=65532:65532 Entrypoint=["/bin/quicknotes"] ExposedPorts={"8080/tcp":{}}
```

Lab 6 Docker-built images:

```text
REPOSITORY   TAG       IMAGE ID                                                                  CREATED         SIZE
qn-lab6      run2      sha256:95a8c6b32ac0d110fee34fb78b260fe4d3bdf6ddebbffba1cea8c7dd9300302a   7 seconds ago   22.7MB
qn-lab6      run1      sha256:abda0376ffacc3011ca968b8d250d2121944509c17e633011f0305971c221113   2 minutes ago   22.7MB
```

The Nix-built image was `9,493,418` bytes by Docker inspect. The Lab 6 Docker images showed `22.7MB` in `docker images`, while Docker inspect reported `5,710,433` bytes for each image. The important reproducibility difference is that the Nix image tarball digest was identical across independent builds, while the Lab 6 Docker image IDs differed.

### Lab 6 Dockerfile comparison

The Lab 6 image was built twice with `--no-cache`:

```bash
DOCKER_BUILDKIT=0 docker build --no-cache -t qn-lab6:run1 "$LAB6_CTX"
DOCKER_BUILDKIT=0 docker build --no-cache -t qn-lab6:run2 "$LAB6_CTX"
docker images --no-trunc qn-lab6
```

Output:

```text
REPOSITORY   TAG       IMAGE ID                                                                  CREATED         SIZE
qn-lab6      run2      sha256:95a8c6b32ac0d110fee34fb78b260fe4d3bdf6ddebbffba1cea8c7dd9300302a   7 seconds ago   22.7MB
qn-lab6      run1      sha256:abda0376ffacc3011ca968b8d250d2121944509c17e633011f0305971c221113   2 minutes ago   22.7MB
```

Detailed inspect output:

```text
run1 ID=sha256:abda0376ffacc3011ca968b8d250d2121944509c17e633011f0305971c221113 Size=5710433 Created=2026-07-01T21:38:43.175072968Z User=nonroot:nonroot Entrypoint=["/quicknotes"] ExposedPorts={"8080/tcp":{}}

run2 ID=sha256:95a8c6b32ac0d110fee34fb78b260fe4d3bdf6ddebbffba1cea8c7dd9300302a Size=5710433 Created=2026-07-01T21:41:07.483729999Z User=nonroot:nonroot Entrypoint=["/quicknotes"] ExposedPorts={"8080/tcp":{}}
```

The two Lab 6 Docker builds produced different image IDs:

```text
run1: sha256:abda0376ffacc3011ca968b8d250d2121944509c17e633011f0305971c221113
run2: sha256:95a8c6b32ac0d110fee34fb78b260fe4d3bdf6ddebbffba1cea8c7dd9300302a
```

This shows that the normal Docker build is not bit-reproducible in this comparison, mainly because Docker records fresh image/layer metadata such as creation timestamps.

### Design questions

#### e) `dockerTools.buildImage` produces a deterministic image. What does Docker's `docker build` do that introduces non-determinism, even from the same Dockerfile + Git SHA?

Docker `docker build` creates new layers and image metadata during each build. Those layers include fresh creation timestamps, generated layer IDs, and metadata from each build step. Even if the Dockerfile and Git SHA are the same, two `--no-cache` builds can produce different image IDs because the build process records when each layer was created.

In the Lab 6 comparison, the two images had the same Dockerfile and same build context, but different image IDs and different `Created` timestamps:

```text
run1 Created=2026-07-01T21:38:43.175072968Z
run2 Created=2026-07-01T21:41:07.483729999Z
```

#### f) For a security auditor, what can you prove with a reproducible image that you cannot prove with a signed-but-non-reproducible image?

With a reproducible image, an auditor can rebuild the image from the same source, lockfile, and build instructions, then compare the resulting digest. If the digest matches, the auditor has strong evidence that the published image came from the reviewed source and pinned dependencies.

A signed but non-reproducible image proves who signed the artifact, but it does not prove that the artifact was built from the claimed source code. If the build cannot be reproduced, the auditor still has to trust the builder or signer.

#### g) What's the trade-off of Nix's reproducibility? Why is `docker build` still the default for most teams?

The trade-off is complexity and adoption cost. Nix requires learning flakes, lockfiles, derivations, the Nix store model, and Nix-specific debugging. It also needs a working Nix setup in local development and CI.

`docker build` is still the default for most teams because it is widely known, integrated into most CI/CD systems, supported by many hosting platforms, and easier for developers to understand. Dockerfiles are also the common deployment format for many production environments. Nix gives stronger reproducibility, but Docker usually gives faster onboarding and simpler team adoption.


---

## Bonus Task — CI-Verified Reproducibility

### Workflow YAML

The bonus workflow is implemented in `.github/workflows/nix-repro.yml`.

```yaml
name: Nix Reproducibility

on:
  push:
    branches:
      - "**"
  pull_request:

permissions:
  contents: read

jobs:
  build-a:
    name: Build image A
    runs-on: ubuntu-24.04
    outputs:
      digest: ${{ steps.digest.outputs.digest }}
    steps:
      - name: Checkout repository
        uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683

      - name: Install Nix
        uses: cachix/install-nix-action@8aa03977d8d733052d78f4e008a241fd1dbf36b3
        with:
          extra_nix_config: |
            experimental-features = nix-command flakes

      - name: Build deterministic OCI image
        run: nix build .#docker

      - name: Compute image tarball digest
        id: digest
        run: |
          digest="$(sha256sum result | awk '{print $1}')"
          echo "digest=$digest" >> "$GITHUB_OUTPUT"
          echo "digest=$digest"

  build-b:
    name: Build image B
    runs-on: ubuntu-24.04
    outputs:
      digest: ${{ steps.digest.outputs.digest }}
    steps:
      - name: Checkout repository
        uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683

      - name: Install Nix
        uses: cachix/install-nix-action@8aa03977d8d733052d78f4e008a241fd1dbf36b3
        with:
          extra_nix_config: |
            experimental-features = nix-command flakes

      - name: Build deterministic OCI image
        run: nix build .#docker

      - name: Compute image tarball digest
        id: digest
        run: |
          digest="$(sha256sum result | awk '{print $1}')"
          echo "digest=$digest" >> "$GITHUB_OUTPUT"
          echo "digest=$digest"

  compare-digests:
    name: Compare image digests
    runs-on: ubuntu-24.04
    needs:
      - build-a
      - build-b
    steps:
      - name: Compare digests
        run: |
          echo "digest A: ${{ needs.build-a.outputs.digest }}"
          echo "digest B: ${{ needs.build-b.outputs.digest }}"

          if [ "${{ needs.build-a.outputs.digest }}" != "${{ needs.build-b.outputs.digest }}" ]; then
            echo "Digest mismatch: reproducibility check failed"
            exit 1
          fi

          echo "Digests match: reproducibility check passed"
```

The workflow triggers on pushes to any branch and on pull requests. It runs two independent jobs, `build-a` and `build-b`, on fresh `ubuntu-24.04` runners. Each job checks out the repository, installs Nix using a 40-character pinned action SHA, builds `.#docker`, computes `sha256sum result`, and exposes the digest as a job output. The third job, `compare-digests`, consumes both outputs and fails if they differ.

Pinned actions used:

```text
actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683
cachix/install-nix-action@8aa03977d8d733052d78f4e008a241fd1dbf36b3
```

### Green CI run

Latest green run:

```text
https://github.com/giselesikeh/DevOps-Intro/actions/runs/28553004516
```

Run summary:

```text
Workflow: Nix Reproducibility
Run: lab11 restore reproducible ci check #3
Commit: 7080ae0
Branch: feature/lab11
Status: Success
Total duration: 51s
Jobs:
- Build image A
- Build image B
- Compare image digests
```

Compare job log excerpt:

```text
digest A: 22a98074d6b89b757810ef7411ee52962991d2189c9b2e24c6fa912ac16c2c16
digest B: 22a98074d6b89b757810ef7411ee52962991d2189c9b2e24c6fa912ac16c2c16
Digests match: reproducibility check passed
```

This confirms that the two fresh CI runners produced identical Nix-built OCI image digests.

### Red CI run showing divergence was caught

Broken red run:

```text
https://github.com/giselesikeh/DevOps-Intro/actions/runs/28552857395
```

Run summary:

```text
Workflow: Nix Reproducibility
Run: lab11 demonstrate ci digest mismatch #2
Commit: 0e14639
Branch: feature/lab11
Status: Failure
Total duration: 46s
Jobs:
- Build image A
- Build image B
- Compare image digests
```

For this proof, I deliberately changed only job A so that it hashed a modified copy of the image tarball:

```bash
cp -L result broken-result
printf 'deliberate-ci-divergence' >> broken-result
digest="$(sha256sum broken-result | awk '{print $1}')"
```

That made job A and job B produce different digest outputs, and the `compare-digests` job correctly failed the workflow. After confirming the red run, I restored the clean workflow and pushed again. The restored run passed.

### Design questions

#### h) What's the difference between "reproducible on my laptop" and "reproducible in CI" that makes the CI proof load-bearing for a security auditor?

“Reproducible on my laptop” proves that the build can be repeated in one local environment, but that environment may contain hidden state: local caches, installed tools, configuration, credentials, or files that are not part of the repository.

“Reproducible in CI” is stronger because CI starts from clean, short-lived runners. The workflow checks out the repository, installs the pinned Nix environment, builds the image, and compares outputs automatically. For a security auditor, this is more useful because the proof is repeatable, public in the project history, and not dependent on trusting one developer’s laptop.

#### i) Why two parallel jobs instead of one job that runs `nix build` twice? What could a single-job two-build comparison miss?

Two parallel jobs run on separate fresh runners. This better simulates independent builds because each job gets its own filesystem, cache state, environment, process tree, and runner metadata.

A single job that runs `nix build` twice could accidentally reuse the first result from the same Nix store or local cache. That might hide problems caused by environmental differences. Two independent jobs make the comparison stricter because the two digests must match across separate CI environments.

#### j) `SOURCE_DATE_EPOCH` is the canonical env var for forcing build timestamps. Where in your Nix flake would the timestamp normally leak in, and how does `dockerTools.buildImage` handle it?

The timestamp would normally leak into the OCI image metadata and layer metadata. In a normal Docker build, every layer and the final image can get fresh creation timestamps, which is why two Docker builds from the same Dockerfile can have different image IDs.

In this flake, the Nix-built image uses:

```nix
created = "1970-01-01T00:00:01Z";
```

inside `pkgs.dockerTools.buildImage`. This fixes the image creation time instead of using the current clock time. Combined with Nix’s pinned inputs and deterministic store paths, this prevents timestamp metadata from changing the final image tarball digest.

---