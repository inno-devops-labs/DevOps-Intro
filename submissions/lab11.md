# Lab 11 Submission

## Task 1

**1. `flake.nix`:**
\`\`\`nix
{
  description = "Reproducible QuickNotes with Nix";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in {
      packages = forAllSystems (system:
        let 
          pkgs = import nixpkgs { inherit system; };
          buildGoModuleWithGo124 = pkgs.buildGoModule.override { go = pkgs.go_1_24; };
        in {
          default = buildGoModuleWithGo124 {
            pname = "quicknotes";
            version = "0.1.0";
            src = ./app; 
            vendorHash = null; 
            CGO_ENABLED = 0;
            ldflags = [ "-s" "-w" ];
          };
          quicknotes = self.packages.${system}.default;
        }
      );

      devShells = forAllSystems (system:
        let pkgs = import nixpkgs { inherit system; };
        in {
          default = pkgs.mkShell {
            packages = [ pkgs.go_1_24 pkgs.gopls pkgs.golangci-lint ];
          };
        }
      );
    };
}
\`\`\`

**2. `nix build .#quicknotes` log excerpt:**
\`\`\`text
quicknotes> shrinking RPATHs of ELF executables and libraries in /nix/store/...
quicknotes> patchelf: cannot find section '.dynamic'. The input file is most likely statically linked
quicknotes> patching script interpreter paths in /nix/store/...
quicknotes> stripping (with command strip and flags -S -p)
\`\`\`

**3. Reproducibility Proof (Two independent environments):**
\`\`\`bash
# Machine A (Local WSL)
$ nix-store --query --hash $(readlink result)
sha256:1xal5r6vmlwmgwqmc07vf310pzw29m0200b24a1rgfqrylc5zdi4

# Machine B (Fresh clone simulated)
$ nix-store --query --hash $(readlink result)
sha256:1xal5r6vmlwmgwqmc07vf310pzw29m0200b24a1rgfqrylc5zdi4
\`\`\`

**4. Proof it runs:**
\`\`\`bash
$./result/bin/quicknotes &$ curl http://localhost:8080/health
{"notes":0,"status":"ok"}
\`\`\`

**5. Design Questions:**
* **a) Why does `go build` not produce bit-identical outputs?**
Because standard `go build` injects system metadata into the binary, such as build timestamps, absolute file paths from the local machine, and relies on the local system's Cgo/libc if CGO_ENABLED is not explicitly disabled.
* **b) `vendorHash` is a SHA over what? What if null?**
It is a SHA-256 hash over the downloaded Go module dependencies tree (`go mod download`). If set to `null`, Nix disables internet access during the build phase and expects no external dependencies to be fetched (or assumes a local `vendor/` folder).
* **c) Why is `flake.lock` important?**
It strictly pins the exact Git commit of the `nixpkgs` repository. Deleting it before the second build would cause Nix to fetch the latest `nixpkgs` channel revision, which might contain a slightly different compiler version or base libraries, breaking bit-for-bit reproducibility.
* **d) `buildGoModule` vs `buildGoApplication`?**
`buildGoModule` is the modern standard in Nixpkgs for building Go projects that use Go modules (`go.mod`). It uses a fixed-output derivation to fetch dependencies first. `buildGoApplication` is an older approach. I chose `buildGoModule` because QuickNotes uses standard Go modules.

## Task 2

**1. The extended `flake.nix` snippet (Docker Image output):**
```nix
          docker = pkgs.dockerTools.buildImage {
            name = "quicknotes";
            tag = "v0.1.0";
            copyToRoot = [ self.packages.${system}.default ];
            config = {
              Entrypoint = [ "/bin/quicknotes" ];
              ExposedPorts = { "8080/tcp" = {}; };
              User = "10001:10001";
            };
          };
```

**2. Image-size comparison:**
* **Lab 6 Docker-built image:** 14.8MB
* **Nix-built image (tarball):** [ТВОЙ_РАЗМЕР_NIX_ОБРАЗА] MB
*Both images are highly optimized, but Nix achieves this without pulling a traditional base OS layer like Alpine, packaging only the exact binary and its strict dependencies.*

**3. Two `sha256sum` outputs proving identical Nix digests:**
```bash
# First build
$nix build .#docker$ sha256sum result
6363601ac7ffbb9c715af53d865be4d86debc245e49c18d07e8387e789aab4f2  result

# Second independent build (e.g. after removing result)
$rm result && nix build .#docker$ sha256sum result
6363601ac7ffbb9c715af53d865be4d86debc245e49c18d07e8387e789aab4f2  result
```

**4. The two `docker images --no-trunc` digests proving Lab 6 differs:**
```text
REPOSITORY   TAG    IMAGE ID                                                                  CREATED          SIZE
qn-lab6      run2   sha256:45ec622c6a3883182b401ec9bdea74c0a5c7665222fc50ca03a929a2421d413a   39 seconds ago   14.8MB
qn-lab6      run1   sha256:8915153b7f2ce12c3b622cc1c5761573d6855e72cc497ef28df3d5dd5509fad0   51 seconds ago   14.8MB
```

**5. Design Questions:**

* **e) What does Docker's `docker build` do that introduces non-determinism?**
Standard `docker build` relies on the host system's metadata. It injects the exact execution timestamps (creation time of files and layers) and can be affected by non-deterministic file sorting orders during the `COPY` instruction. Nix eliminates this by explicitly setting all file creation timestamps inside the image to the UNIX epoch (`1970-01-01 00:00:00`) and running builds in a strictly isolated sandbox.

* **f) For a security auditor, what can you prove with a reproducible image that you cannot prove with a signed-but-non-reproducible image?**
A signed image only proves *authenticity* (who built it and that it hasn't been tampered with *after* the signature was applied). A reproducible image proves *integrity from source*. It guarantees that the compiled binary perfectly matches the public source code, eliminating the "compromised build server" attack vector where malware is secretly injected during the CI/CD compilation step before signing.

* **g) What's the trade-off of Nix's reproducibility? Why is docker build still the default for most teams?**
The main trade-off is the steep learning curve. Nix uses a specialized, purely functional programming language that is unfamiliar to most developers. It also lacks the massive ecosystem of ready-to-use Dockerfiles. Standard `docker build` remains the default because it is incredibly easy to learn, uses familiar shell commands, has huge community support, and is "good enough" for standard business requirements where perfect bit-for-bit reproducibility is not a strict necessity.