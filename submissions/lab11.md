# Lab 11 - Reproducible Builds of QuickNotes with Nix

## Repository freshness

Before starting, I fetched the course repo:

```text
git fetch upstream main --prune
upstream/main -> 8de962e docs(lab11): fix nixpkgs pin vs go.mod collision; add network fallback pitfalls
```

`feature/lab11` was created from that fresh `upstream/main`, so this work uses the updated Lab 11 spec.

## Implemented files

- [`flake.nix`](../flake.nix)
- [`flake.lock`](../flake.lock)
- [`.github/workflows/nix-repro.yml`](../.github/workflows/nix-repro.yml)
- [`security/lab11/lab6-baseline.Dockerfile`](../security/lab11/lab6-baseline.Dockerfile)
- [`security/lab11/repro-evidence.txt`](../security/lab11/repro-evidence.txt)
- [`submissions/lab11.md`](../submissions/lab11.md)

## Task 1 - Reproducible Go build via Nix

The flake pins `nixos-25.11`, locked to nixpkgs commit `b6018f87da91d19d0ab4cf979885689b469cdd41`. That channel provides Go `1.24.13`, matching `app/go.mod`.

Key `flake.nix` package output:

```nix
buildGoModule = pkgs.buildGoModule.override { go = pkgs.go_1_24; };

quicknotes = buildGoModule {
  pname = "quicknotes";
  version = "0.1.0";

  src = quicknotesSrc;
  subPackages = [ "." ];

  env.CGO_ENABLED = "0";
  ldflags = [
    "-s"
    "-w"
  ];

  vendorHash = null;

  postInstall = ''
    install -Dm0644 seed.json $out/share/quicknotes/seed.json
  '';
};
```

`vendorHash = null` is intentional for this repository: `app/go.mod` has no third-party dependencies, and `buildGoModule` fails with "vendor folder is empty, please set 'vendorHash = null;'" if a fake hash is supplied.

Build log excerpt:

```text
nix build .#quicknotes
OUT=/nix/store/dzv3p2bihk852l3zvjhayyjlf3c33kag-quicknotes-0.1.0
-r-xr-xr-x 1 root root 5.6M Jan  1  1970 .../bin/quicknotes
```

Two independent Nix containers produced identical store hashes:

```text
container A:
nix-store --query --hash /nix/store/dzv3p2bihk852l3zvjhayyjlf3c33kag-quicknotes-0.1.0
sha256:1gvzai334rp8m2pdfrhf2g3zdbvfg098qcyladrdlinm9bgg9gin

container B:
nix-store --query --hash /nix/store/dzv3p2bihk852l3zvjhayyjlf3c33kag-quicknotes-0.1.0
sha256:1gvzai334rp8m2pdfrhf2g3zdbvfg098qcyladrdlinm9bgg9gin
```

Runtime proof for the raw Nix-built binary:

```text
RUNNING=/nix/store/dzv3p2bihk852l3zvjhayyjlf3c33kag-quicknotes-0.1.0
curl http://localhost:18081/health
{"notes":4,"status":"ok"}
```

### Design answers a-d

**a) Why `go build` is not bit-identical by default**

Plain `go build` can include local path information, build IDs, module-resolution differences, timestamps from generated artifacts, and dependency versions resolved outside a locked environment. Even with the same Git SHA, two machines can have different Go patch versions, module cache state, OS tooling, and environment variables.

**b) What `vendorHash` covers**

For a Go module with dependencies, `vendorHash` is the fixed-output hash of the vendored module dependency tree that Nix creates from `go.mod` and `go.sum`. If it is wrong, Nix refuses the build and prints the expected hash. In this repo there are no third-party modules, so `vendorHash = null` is the correct reproducible declaration; supplying a fake hash makes `buildGoModule` fail because there is no vendor tree to hash.

**c) Why `flake.lock` matters**

`flake.lock` pins the exact nixpkgs revision and nar hash. That pins Go, `buildGoModule`, `dockerTools`, stdenv, and every transitive build tool. If it is deleted before the second build, Nix may resolve `nixos-25.11` to a newer commit and silently change the build graph.

**d) `buildGoModule` vs `buildGoApplication`**

`buildGoModule` is the standard nixpkgs builder for Go modules and works directly with `go.mod`, fixed dependency vendoring, `ldflags`, and package installation. `buildGoApplication` is useful in ecosystems that prefer `gomod2nix`-style dependency materialization. I chose `buildGoModule` because QuickNotes is a tiny stdlib-only module and nixpkgs already handles it cleanly.

## Task 2 - Deterministic OCI image

The flake exposes `.#docker` using `pkgs.dockerTools.buildImage`.

Key image output:

```nix
docker = pkgs.dockerTools.buildImage {
  name = "quicknotes";
  tag = "nix";
  created = "1970-01-01T00:00:01Z";

  copyToRoot = quicknotesRoot;

  extraCommands = ''
    mkdir -p data tmp
    chmod 0777 data
    chmod 1777 tmp
  '';

  config = {
    User = "65532:65532";
    Entrypoint = [ "/bin/quicknotes" ];
    Env = [
      "ADDR=:8080"
      "DATA_PATH=/data/notes.json"
      "SEED_PATH=/share/quicknotes/seed.json"
    ];
    ExposedPorts = {
      "8080/tcp" = { };
    };
    WorkingDir = "/";
  };
};
```

Two independent Nix containers produced identical OCI tarball hashes:

```text
container A:
nix build .#docker
sha256sum result
0dd58ba83183c05e3c418f2aa3dd7a213778b3c93cddb9edb9b913ce111d7827  result

container B:
nix build .#docker
sha256sum result
0dd58ba83183c05e3c418f2aa3dd7a213778b3c93cddb9edb9b913ce111d7827  result
```

Image load and run proof:

```text
docker load -i security/lab11/quicknotes-nix.tar
Loaded image: quicknotes:nix

docker image inspect quicknotes:nix --format 'id={{.Id}} size={{.Size}} user={{.Config.User}} entrypoint={{json .Config.Entrypoint}} ports={{json .Config.ExposedPorts}}'
id=sha256:8efbbfc5682ea1900b64734559dfa8f3d67fed683b5ad2e29c5c4a00f2ad183b size=9503762 user=65532:65532 entrypoint=["/bin/quicknotes"] ports={"8080/tcp":{}}

curl http://localhost:18080/health
{"notes":4,"status":"ok"}
```

Image-size comparison:

| Image | Size evidence |
|---|---:|
| Nix `quicknotes:nix` loaded image | 9,503,762 bytes |
| Nix OCI tarball | 3.0 MB |
| Lab 6-style Docker baseline `qn-lab6:run1` | 2,504,917 bytes |

Lab 6-style Docker baseline comparison:

```text
docker build --no-cache -f security/lab11/lab6-baseline.Dockerfile -t qn-lab6:run1 app
docker build --no-cache -f security/lab11/lab6-baseline.Dockerfile -t qn-lab6:run2 app

docker images --no-trunc qn-lab6
qn-lab6 run1 sha256:0d880f581f13eb89661833758214722f01fe8b7eac0f3dc7d092fdfaf780f30d 8.39MB
qn-lab6 run2 sha256:b6ec4bcbf2805e1ed59f7421934d0c5092fa79552f7c5ee2b2bbc3c2fc87cd09 8.39MB

docker image inspect:
tag=qn-lab6:run1 id=sha256:0d880f581f13eb89661833758214722f01fe8b7eac0f3dc7d092fdfaf780f30d created=2026-07-07T10:14:26.174297646Z
tag=qn-lab6:run2 id=sha256:b6ec4bcbf2805e1ed59f7421934d0c5092fa79552f7c5ee2b2bbc3c2fc87cd09 created=2026-07-07T10:14:34.916363945Z
```

### Design answers e-g

**e) Why Docker builds differ**

Docker records image config creation time, layer metadata, build provenance/attestation metadata, and exporter details. Even when the compiled binary is identical, the image manifest/config can change between `--no-cache` runs. In the baseline evidence, the two Docker images differ and their `created` timestamps differ by several seconds.

**f) What reproducible images prove to an auditor**

A signature proves who signed an artifact. Reproducibility proves that an auditor can independently rebuild the source and obtain the same artifact digest. That connects source, dependency lock, build recipe, and image bytes; a signed but non-reproducible image still requires trusting the builder that produced it.

**g) Trade-off of Nix reproducibility**

Nix asks teams to learn a new packaging language, maintain lockfiles and hashes, and adapt debugging workflows around the Nix store. Docker remains the default because it is simpler for most developers, well integrated with registries and platforms, and maps directly to common production workflows even when it is less reproducible by default.

## Bonus Task - CI-verified reproducibility

Workflow: [`.github/workflows/nix-repro.yml`](../.github/workflows/nix-repro.yml)

The workflow triggers on pushes, pull requests, and manual dispatch. It has two parallel build jobs on fresh `ubuntu-24.04` runners and one compare job. `actions/checkout` and `cachix/install-nix-action` are pinned to 40-character SHAs.

Green run:

```text
Run: https://github.com/BearAx/DevOps-Intro/actions/runs/28859123120
build A: https://github.com/BearAx/DevOps-Intro/actions/runs/28859123120/job/85592996750
build B: https://github.com/BearAx/DevOps-Intro/actions/runs/28859123120/job/85592996813
compare: https://github.com/BearAx/DevOps-Intro/actions/runs/28859123120/job/85593131697
Conclusion: success
```

Red run:

```text
Run: https://github.com/BearAx/DevOps-Intro/actions/runs/28859027758
compare: https://github.com/BearAx/DevOps-Intro/actions/runs/28859027758/job/85592815606
Conclusion: failure
```

For the red demonstration, commit `f3dd99b` deliberately perturbed build A's reported digest before the compare job. I used a digest perturbation rather than an ambient `SOURCE_DATE_EPOCH` environment change because the Nix derivation is pure and does not read arbitrary CI environment variables unless the flake explicitly wires them in.

### Design answers h-j

**h) Laptop proof vs CI proof**

A laptop proof is useful, but it can hide local caches, uncommitted files, and machine-specific setup. CI proof is load-bearing because the rebuild happens on fresh hosted runners from the pushed commit and locked inputs. That gives an auditor an external, repeatable signal.

**i) Why two parallel jobs**

One job that runs `nix build` twice can reuse the same local Nix store, daemon, checkout, and runner state. Two parallel jobs use separate fresh runners, so the comparison catches problems masked by same-machine cache reuse.

**j) `SOURCE_DATE_EPOCH` and `dockerTools.buildImage`**

Timestamp leakage would normally enter through archive mtimes, generated files, Go build metadata, or image config creation time. The flake avoids that by using Nix's normalized store outputs, Go's trimmed build flags from `buildGoModule`, and an explicit `created = "1970-01-01T00:00:01Z"` for `dockerTools.buildImage`.
