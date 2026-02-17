# Lab 11 — Reproducible Builds with Nix

![difficulty](https://img.shields.io/badge/difficulty-intermediate-yellow)
![topic](https://img.shields.io/badge/topic-Nix%20%26%20Reproducibility-blue)
![points](https://img.shields.io/badge/points-12-orange)

> **Goal:** Learn to create truly reproducible builds using Nix, eliminating "works on my machine" problems and achieving bit-for-bit reproducibility.
> **Deliverable:** A PR/MR from `feature/lab11` to the course repo with `labs/submission11.md` containing build artifacts, hash comparisons, Nix expressions, and analysis. Submit the PR/MR link via Moodle.

---

## Overview

In this lab you will practice:
- Installing Nix and understanding the Nix philosophy
- Writing Nix derivations to build software reproducibly
- Creating reproducible Docker images using Nix
- Using Nix Flakes for modern, declarative dependency management
- Comparing Nix's reproducibility guarantees with traditional build tools

**Why Nix?** Traditional build tools (Docker, npm, pip, etc.) claim to be reproducible, but they're not:
- `Dockerfile` with `apt-get install nodejs` gets different versions over time
- `npm install` without lockfiles is non-deterministic
- Docker builds include timestamps and vary across machines

**Nix solves this:** Every build is isolated in a sandbox with exact dependencies. The same Nix expression produces **identical binaries** on any machine, forever.

---

## Prerequisites

- Linux, macOS, or WSL2
- Basic understanding of package managers
- Familiarity with Docker (from Lab 6)
- Git knowledge (from Labs 1-2)

---

## Tasks

### Task 1 — Build Reproducible Artifacts from Scratch (6 pts)

**Objective:** Write a Nix derivation to build a simple application and prove it produces bit-for-bit identical results across different builds and machines.

**Why This Matters:** Traditional build tools fail at true reproducibility. Nix's content-addressable store and sandboxed builds guarantee that the same input always produces the same output, enabling perfect reproducibility.

#### 1.1: Install Nix Package Manager

1. **Install Nix using the Determinate Systems installer (recommended):**

   ```bash
   curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
   ```

   > **Why Determinate Nix?** It enables flakes by default and provides better defaults for modern Nix usage.

   <details>
   <summary>🐧 Alternative: Official Nix installer</summary>

   ```bash
   sh <(curl -L https://nixos.org/nix/install) --daemon
   ```

   Then enable flakes by adding to `~/.config/nix/nix.conf`:
   ```
   experimental-features = nix-command flakes
   ```

   </details>

2. **Verify Installation:**

   ```bash
   nix --version
   ```

   You should see Nix 2.x or higher.

3. **Test Basic Nix Usage:**

   ```bash
   # Try running a program without installing it
   nix run nixpkgs#hello
   ```

   This downloads and runs `hello` without installing it permanently.

#### 1.2: Create a Simple Application

1. **Create a lab directory:**

   ```bash
   mkdir -p labs/lab11/app
   cd labs/lab11/app
   ```

2. **Write a simple Go application:**

   Create `main.go`:

   ```go
   package main

   import (
       "fmt"
       "time"
   )

   func main() {
       fmt.Printf("Built with Nix at compile time\n")
       fmt.Printf("Running at: %s\n", time.Now().Format(time.RFC3339))
   }
   ```

   > **Note:** We're using Go because it compiles to a single binary, making it easy to verify reproducibility. The same principles apply to any language.

#### 1.3: Write a Nix Derivation

1. **Create a Nix derivation:**

   Create `default.nix` in the same directory:

   <details>
   <summary>📚 Where to learn Nix derivation syntax</summary>

   - [Nix Pills - Chapter 6: Our First Derivation](https://nixos.org/guides/nix-pills/our-first-derivation.html)
   - [nix.dev - Declarative builds](https://nix.dev/tutorials/first-steps/declarative-shell)
   - [Zero to Nix - Building with Nix](https://zero-to-nix.com/concepts/derivations)

   **Key concepts you need:**
   - `pkgs.buildGoModule` - Function to build Go applications
   - `pname` - Package name
   - `version` - Package version
   - `src` - Source code location (use `./. ` for current directory)
   - `vendorHash` - Hash of Go dependencies (use `pkgs.lib.fakeHash` initially, then fix)

   **Hint:** Look at examples in nixpkgs for Go applications.

   </details>

2. **Build your application:**

   ```bash
   nix-build
   ```

   This creates a `result` symlink pointing to the Nix store path.

3. **Run the built binary:**

   ```bash
   ./result/bin/app
   ```

#### 1.4: Prove Reproducibility

1. **Record the store path:**

   ```bash
   readlink result
   ```

   Note the Nix store path (e.g., `/nix/store/abc123.../`)

2. **Build again and compare:**

   ```bash
   rm result
   nix-build
   readlink result
   ```

   **Question:** Is the store path identical?

3. **Compute hash of the binary:**

   ```bash
   sha256sum ./result/bin/app
   ```

4. **Compare with Docker (non-reproducible):**

   Create a `Dockerfile`:

   ```dockerfile
   FROM golang:1.22
   WORKDIR /app
   COPY main.go .
   RUN go build -o app main.go
   ```

   Build twice:

   ```bash
   docker build -t test-app .
   docker build -t test-app .
   ```

   Docker images will have different hashes even with identical content!

In `labs/submission11.md`, document:
- Installation steps and verification output
- Your `default.nix` file with explanations
- Store path from multiple builds (prove they're identical)
- SHA256 hash of the binary
- Comparison with Docker: Why is Docker not reproducible?
- Analysis: What makes Nix builds reproducible?
- Explanation of the Nix store path format and what each part means

---

### Task 2 — Reproducible Docker Images with Nix (4 pts)

**Objective:** Use Nix's `dockerTools` to create truly reproducible Docker images and compare them with traditional Dockerfiles.

**Why This Matters:** Traditional Dockerfiles are not reproducible - they include timestamps, pull latest packages, and vary across builds. Nix-built Docker images are content-addressable and reproducible.

#### 2.1: Build Docker Image with Nix

1. **Create a Docker image using `dockerTools`:**

   Create `docker.nix`:

   <details>
   <summary>📚 Where to learn about dockerTools</summary>

   - [nix.dev - Building Docker images](https://nix.dev/tutorials/nixos/building-and-running-docker-images.html)
   - [nixpkgs dockerTools documentation](https://ryantm.github.io/nixpkgs/builders/images/dockertools/)

   **Key concepts:**
   - `pkgs.dockerTools.buildLayeredImage` - Builds efficient layered images
   - `name` - Image name
   - `tag` - Image tag
   - `contents` - Packages to include in the image
   - `config.Cmd` - Default command to run

   **Important:** Avoid using `created = "now"` as it breaks reproducibility!

   **Hint:** You can use the derivation from Task 1 as `contents`.

   </details>

2. **Build the Docker image:**

   ```bash
   nix-build docker.nix
   ```

   This creates a tarball in `result`.

3. **Load into Docker:**

   ```bash
   docker load < result
   ```

4. **Run the container:**

   ```bash
   docker run <your-image-name>
   ```

#### 2.2: Compare Image Sizes and Reproducibility

1. **Check Nix-built image size:**

   ```bash
   docker images | grep <your-image-name>
   ls -lh result
   ```

2. **Build equivalent traditional Dockerfile:**

   Create a minimal `Dockerfile.traditional`:

   ```dockerfile
   FROM scratch
   COPY --from=golang:1.22 /path/to/binary /app
   ENTRYPOINT ["/app"]
   ```

   Build it:

   ```bash
   docker build -f Dockerfile.traditional -t traditional-app .
   ```

3. **Compare image sizes:**

   ```bash
   docker images | grep -E "your-image-name|traditional-app"
   ```

4. **Test reproducibility:**

   Build the Nix image twice on different days (or simulate with `--option build-repeat 2`):

   ```bash
   nix-build docker.nix --option build-repeat 2
   sha256sum result
   ```

   **Question:** Are the hashes identical?

#### 2.3: Inspect Image Layers

1. **Examine Nix image layers:**

   ```bash
   docker history <your-nix-image>
   ```

2. **Compare with traditional image:**

   ```bash
   docker history traditional-app
   ```

   Note the differences in layer structure and creation timestamps.

In `labs/submission11.md`, document:
- Your `docker.nix` file with explanations
- Image size comparison: Nix vs traditional Dockerfile
- SHA256 hashes proving reproducibility
- Docker history output for both images
- Analysis: Why are Nix-built images smaller and more reproducible?
- Layer structure comparison
- Practical advantages of content-addressable Docker images

---

### Bonus Task — Modern Nix with Flakes (2 pts)

**Objective:** Modernize your Nix expressions using Flakes for better dependency locking and reproducibility.

**Why This Matters:** Nix Flakes are the modern standard (2026) for Nix projects. They provide:
- Automatic dependency locking via `flake.lock`
- Standardized project structure
- Better reproducibility across time
- Easier sharing and collaboration

#### Bonus.1: Convert to Flake

1. **Create a `flake.nix`:**

   <details>
   <summary>📚 Where to learn about Flakes</summary>

   - [Zero to Nix - Flakes](https://zero-to-nix.com/concepts/flakes)
   - [NixOS Wiki - Flakes](https://wiki.nixos.org/wiki/Flakes)
   - [Nix Flakes explained](https://nix.dev/concepts/flakes)

   **Key structure:**
   ```nix
   {
     description = "My reproducible app";

     inputs = {
       nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
     };

     outputs = { self, nixpkgs }: {
       packages.x86_64-linux.default = # your derivation
       dockerImages.x86_64-linux.default = # your docker image
     };
   }
   ```

   **Hint:** Use `nix flake init` to generate a template, then modify it.

   </details>

2. **Generate lock file:**

   ```bash
   nix flake update
   ```

   This creates `flake.lock` with pinned dependencies.

3. **Build using flake:**

   ```bash
   nix build
   nix build .#dockerImages.x86_64-linux.default
   ```

#### Bonus.2: Test Portability

1. **Commit your flake to git:**

   ```bash
   git add flake.nix flake.lock
   git commit -m "feat: add Nix flake for reproducible builds"
   ```

2. **Test on another machine (or ask a classmate):**

   ```bash
   nix build github:yourusername/yourrepo#default
   ```

3. **Compare store paths:**

   Both machines should get identical store paths!

#### Bonus.3: Add Development Shell

1. **Add a dev shell to your flake:**

   Add to `flake.nix` outputs:

   ```nix
   devShells.x86_64-linux.default = pkgs.mkShell {
     buildInputs = [ pkgs.go pkgs.gopls ];
   };
   ```

2. **Enter the dev shell:**

   ```bash
   nix develop
   ```

   This provides a reproducible development environment!

In `labs/submission11.md`, document:
- Your complete `flake.nix` with explanations
- `flake.lock` snippet showing locked dependencies
- Build outputs from `nix build`
- Proof that builds are identical across machines/time
- Dev shell experience: Why is this better than traditional dev setups?
- Reflection: How do Flakes improve upon traditional Nix expressions?

---

## How to Submit

1. Create a branch for this lab and push it:

   ```bash
   git switch -c feature/lab11
   # create labs/submission11.md with your findings
   git add labs/submission11.md labs/lab11/
   git commit -m "docs: add lab11 submission"
   git push -u origin feature/lab11
   ```

2. **Open a PR (GitHub) or MR (GitLab)** from your fork's `feature/lab11` branch → **course repository's main branch**.

3. In the PR/MR description, include:

   ```text
   Platform: [GitHub / GitLab]

   - [x] Task 1 — Build Reproducible Artifacts from Scratch (6 pts)
   - [x] Task 2 — Reproducible Docker Images with Nix (4 pts)
   - [ ] Bonus Task — Modern Nix with Flakes (2 pts) [if completed]
   ```

4. **Copy the PR/MR URL** and submit it via **Moodle before the deadline**.

---

## Acceptance Criteria

- ✅ Branch `feature/lab11` exists with commits for each task
- ✅ File `labs/submission11.md` contains required outputs and analysis for all completed tasks
- ✅ Directory `labs/lab11/` contains your application code and Nix expressions
- ✅ Nix derivations successfully build reproducible artifacts
- ✅ Docker image built with Nix and compared to traditional Dockerfile
- ✅ Hash comparisons prove reproducibility
- ✅ **Bonus (if attempted):** `flake.nix` and `flake.lock` present and working
- ✅ PR/MR from `feature/lab11` → **course repo main branch** is open
- ✅ PR/MR link submitted via Moodle before the deadline

---

## Rubric (12 pts max)

| Criterion                                           | Points |
| --------------------------------------------------- | -----: |
| Task 1 — Build Reproducible Artifacts from Scratch |  **6** |
| Task 2 — Reproducible Docker Images with Nix        |  **4** |
| Bonus Task — Modern Nix with Flakes                 |  **2** |
| **Total**                                           | **12** |

---

## Guidelines

- Use clear Markdown headers to organize sections in `submission11.md`
- Include command outputs and written analysis for each task
- Explain WHY Nix provides better reproducibility than traditional tools
- Compare before/after results when proving reproducibility
- Document challenges encountered and how you solved them
- Include code snippets with explanations, not just paste

<details>
<summary>📚 Helpful Resources</summary>

**Official Documentation:**
- [nix.dev - Official tutorials](https://nix.dev/)
- [Zero to Nix - Beginner-friendly guide](https://zero-to-nix.com/)
- [Nix Pills - Deep dive](https://nixos.org/guides/nix-pills/)
- [NixOS Package Search](https://search.nixos.org/)

**Docker with Nix:**
- [Building Docker images - nix.dev](https://nix.dev/tutorials/nixos/building-and-running-docker-images.html)
- [dockerTools reference](https://ryantm.github.io/nixpkgs/builders/images/dockertools/)

**Flakes:**
- [Nix Flakes - NixOS Wiki](https://wiki.nixos.org/wiki/Flakes)
- [Flakes - Zero to Nix](https://zero-to-nix.com/concepts/flakes)
- [Practical Nix Flakes](https://serokell.io/blog/practical-nix-flakes)

**Community:**
- [awesome-nix - Curated resources](https://github.com/nix-community/awesome-nix)
- [NixOS Discourse](https://discourse.nixos.org/)

</details>

<details>
<summary>💡 Nix Tips</summary>

1. **Store paths are content-addressable:** Same inputs = same output hash
2. **Use `nix-shell -p pkg` for quick testing** before adding to derivations
3. **Garbage collect unused builds:** `nix-collect-garbage -d`
4. **Search for packages:** `nix search nixpkgs golang`
5. **Read error messages carefully:** Nix errors are verbose but informative
6. **Use `lib.fakeHash` initially** when you don't know the hash yet
7. **Avoid network access in builds:** Nix sandboxes block network by default
8. **Pin nixpkgs version** for maximum reproducibility

</details>

<details>
<summary>🔧 Troubleshooting</summary>

**If Nix installation fails:**
- Ensure you have multi-user support (daemon mode recommended)
- Check `/nix` directory permissions
- Try the Determinate Systems installer instead of official

**If builds fail with "hash mismatch":**
- Update the hash in your derivation to match the error message
- Use `lib.fakeHash` to discover the correct hash

**If Docker load fails:**
- Verify result is a valid tarball: `file result`
- Check Docker daemon is running: `docker info`
- Try `docker load -i result` instead of `docker load < result`

**If flakes don't work:**
- Ensure experimental features are enabled in `~/.config/nix/nix.conf`
- Run `nix flake check` to validate flake syntax
- Make sure your flake is in a git repository

**If cross-machine builds differ:**
- Check nixpkgs input is locked in `flake.lock`
- Verify both machines use same Nix version
- Ensure no `created = "now"` or timestamps in image builds

</details>

<details>
<summary>🎯 Understanding Reproducibility</summary>

**What makes a build reproducible?**
- ✅ Deterministic inputs (exact versions, hashes)
- ✅ Isolated environment (no system dependencies)
- ✅ No timestamps or random values
- ✅ Same compiler, same flags, same libraries
- ✅ Content-addressable storage

**Why traditional tools fail:**
```bash
# Docker - timestamps in layers
docker build .  # Different timestamp = different image hash

# npm - lockfiles help but aren't perfect
npm install     # Still uses local cache, system libraries

# apt/yum - version drift
apt-get install nodejs  # Gets different version next week
```

**How Nix succeeds:**
```bash
# Nix - pure, sandboxed, content-addressed
nix-build       # Same inputs = bit-for-bit identical output
                # Today, tomorrow, on any machine
```

**Real-world impact:**
- **CI/CD:** No more "works on my machine"
- **Security:** Audit exact dependency tree
- **Rollback:** Atomic updates with perfect rollbacks
- **Collaboration:** Everyone gets identical environment

</details>

<details>
<summary>🌟 Advanced Concepts (Optional Reading)</summary>

**Content-Addressable Store:**
- Every package has a unique hash based on its inputs
- `/nix/store/abc123...` where `abc123` = hash of inputs
- Same inputs = same hash = reuse existing build

**Sandboxing:**
- Builds run in isolated namespaces
- No network access (except for fixed-output derivations)
- No access to `/home`, `/tmp`, or system paths
- Only declared dependencies are available

**Lazy Evaluation:**
- Nix expressions are lazily evaluated
- Only builds what's actually needed
- Enables massive codebase (all of nixpkgs) without performance issues

**Binary Cache:**
- cache.nixos.org provides pre-built binaries
- If your build matches a cached hash, download instead of rebuild
- Set up private caches for your team

**Cross-Compilation:**
- Nix makes cross-compilation trivial
- `pkgs.pkgsCross.aarch64-multiplatform.hello`
- Same reproducibility guarantees across architectures

</details>
