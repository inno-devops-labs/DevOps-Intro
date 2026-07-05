# Lab 11 — Bonus: Reproducible Builds of QuickNotes with Nix

![difficulty](https://img.shields.io/badge/difficulty-advanced-red)
![topic](https://img.shields.io/badge/topic-Reproducible%20Builds%20%2F%20Nix-blue)
![points](https://img.shields.io/badge/points-4%2B4%2B2-orange)
![tech](https://img.shields.io/badge/tech-Nix%20Flakes%20%2B%20Go-informational)

> **Goal:** Write a Nix flake that builds QuickNotes reproducibly. Extend it to build a deterministic OCI image. Prove that two independent builds produce the same SHA-256 image digest. Bonus: verify reproducibility from CI (two parallel runs, identical digests).
> **Deliverable:** A PR from `feature/lab11` to the course repo with `flake.nix` (+ `flake.lock`) + `submissions/lab11.md`.

> 🎁 **Bonus lab.** 10 pts total, structured as Task 1 (4) + Task 2 (4) + Bonus Task (2). This lab is the bonus; its full 10 pts count toward the bonus-labs grade weight.

---

## Overview

You will not be handed a flake. Read [Reading 11](../lectures/reading11.md) first; then write the flake from requirements + docs.

By the end:
- A `flake.nix` at the repo root builds the QuickNotes binary
- A second flake output builds a deterministic OCI image
- Two independent builds (different machines or `nix store gc`-ed clones) produce **identical** SHA-256 image digests

---

## Project State

**Starting point:** Lab 6 Docker image works. QuickNotes builds with `go build` (Lab 1).

**After this lab:** A flake at the repo root; reproducibility verified across two independent runs.

---

## Prerequisites

- Read [Reading 11](../lectures/reading11.md)
- Install Nix with Flakes enabled:
  - [Determinate Nix Installer](https://determinate.systems/posts/determinate-nix-installer/) (recommended)
  - If `install.determinate.systems` is unreachable or times out from your network, use the [official installer](https://nixos.org/download/) (`sh <(curl -L https://nixos.org/nix/install) --daemon`) — it is served from a different CDN. Enable flakes afterwards: add `experimental-features = nix-command flakes` to `~/.config/nix/nix.conf`
- ≥ 8 GB free disk
- A second machine, fresh Docker container (`docker run -it nixos/nix bash`), or a colleague — for verifying reproducibility

---

## Task 1 — Reproducible Go Build via Nix Flake (4 pts)

### 1.1: Requirements

Your `flake.nix` at the **repo root** MUST:

1. Pin **nixpkgs** to a specific channel revision in `inputs:` (e.g. `nixos-25.11`) — note that `app/go.mod` requires **Go ≥ 1.24**, so the channel's default `buildGoModule` must ship at least that (see Common Pitfalls)
2. Expose a package `quicknotes` (and `default`) that **builds the QuickNotes Go source from `app/`**
3. Use `buildGoModule` (or `buildGoApplication`, etc. — your choice; document why)
4. Set **`CGO_ENABLED = 0`** so the binary is static
5. Pin **`vendorHash`** (you'll get the value from the first failed build — paste it in)
6. Use **`-ldflags = [ "-s" "-w" ]`** for size + reproducibility (carried from Lab 6)
7. Expose a `devShell` with `go`, `gopls`, and `golangci-lint` so collaborators can `nix develop` into the project

The flake MUST commit cleanly together with **`flake.lock`** (auto-generated) so anyone cloning gets the exact same nixpkgs revision.

### 1.2: Verify reproducibility

The proof for Task 1 is that **two independent builds produce identical store hashes**:

```bash
# machine A (or first sandbox)
nix build .#quicknotes
nix-store --query --hash $(readlink result)
# e.g. sha256:abc123...

# machine B (or `docker run -it nixos/nix bash`, fresh clone)
git clone YOUR_FORK qn-fresh
cd qn-fresh
nix build .#quicknotes
nix-store --query --hash $(readlink result)
# MUST match machine A
```

### 1.3: Design questions

- a) **Why does `go build` not produce bit-identical outputs** on two machines, even from the same Git SHA? (Hint: timestamps, vendor resolution, build IDs.)
- b) **`vendorHash`** is a SHA over what, exactly? What happens if you set `vendorHash = null;`?
- c) **`flake.lock`** pins nixpkgs. Why is this the single most important file for reproducibility? What happens if you delete it before the second build?
- d) **`buildGoModule` vs `buildGoApplication`** — what's the difference? Which would you pick for QuickNotes and why?

### 1.4: Where to start

- 📖 [Nix Pills](https://nixos.org/guides/nix-pills/) — chapter 1-5 cover the model
- 📖 [Zero to Nix](https://zero-to-nix.com/) — Determinate's modern walkthrough
- 📖 [`buildGoModule` reference](https://ryantm.github.io/nixpkgs/languages-frameworks/go/) (nixpkgs section)
- 📖 [Flakes reference](https://nixos.wiki/wiki/Flakes)

### 1.5: Document

In `submissions/lab11.md`:
- Your `flake.nix` (paste; flake.lock can be linked)
- `nix build .#quicknotes` log excerpt
- Two `nix-store --query --hash` outputs from two independent environments — identical
- `./result/bin/quicknotes &` + `curl /health` proof it runs
- Design questions a-d answered

---

## Task 2 — Deterministic OCI Image (4 pts)

### 2.1: Requirements

Extend `flake.nix` to expose a `docker` (or similar) package using **`pkgs.dockerTools.buildImage`** that:

1. Produces an OCI image tarball containing the QuickNotes binary from Task 1
2. Sets the binary as `Entrypoint` (exec form)
3. Sets `ExposedPorts` to include `8080/tcp`
4. Runs as a `nonroot` user (carry forward Lab 6's discipline)
5. The image is built **without Docker** — only Nix tooling

### 2.2: Verify reproducibility

The proof for Task 2 is that **two independent builds produce identical SHA-256 image digests**:

```bash
# environment A
nix build .#docker
sha256sum result            # capture digest

# environment B
nix build .#docker
sha256sum result            # MUST match
```

### 2.3: Compare with Lab 6's Dockerfile build

Build the Lab 6 image fresh **twice** with `--no-cache`:

```bash
docker build --no-cache -t qn-lab6:run1 ./app
docker build --no-cache -t qn-lab6:run2 ./app
docker images --no-trunc qn-lab6
```

Typically the Lab 6 digests **differ** (timestamps in the layers).

### 2.4: Design questions

- e) **`dockerTools.buildImage` produces a deterministic image. What does Docker's `docker build` do** that introduces non-determinism, even from the same Dockerfile + Git SHA?
- f) **For a security auditor**, what can you prove with a reproducible image that you *cannot* prove with a signed-but-non-reproducible image?
- g) **What's the trade-off** of Nix's reproducibility? Why is `docker build` still the default for most teams?

### 2.5: Document

In `submissions/lab11.md`:
- The extended `flake.nix` snippet
- Image-size comparison: Nix-built vs Lab 6 Docker-built
- Two `sha256sum` outputs proving identical Nix digests
- The two `docker images --no-trunc` digests proving Lab 6 differs
- Design questions e, f, g answered

---

## Bonus Task — CI-Verified Reproducibility (2 pts)

### B.1: Goal

Reproducibility you can't prove in CI is folklore. Wire your Nix build into **GitHub Actions** (or GitLab CI) so that **two independent runs** in CI produce identical digests — automatically, on every push.

### B.2: Requirements

Add a CI workflow (e.g. `.github/workflows/nix-repro.yml`) that:

1. Triggers on push to any branch + pull requests
2. Runs **two parallel jobs** (or uses a matrix with two cells) — each on a fresh runner
3. Each job:
   - Checks out the repo
   - Installs Nix (use the [Determinate Nix Installer Action](https://github.com/DeterminateSystems/nix-installer-action) or `cachix/install-nix-action` — pinned by SHA)
   - Runs `nix build .#docker`
   - Computes `sha256sum result | awk '{print $1}'`
   - Uploads that digest as a job output
4. A **third job** consumes both outputs and **fails the workflow** if they differ
5. **Pin** the Nix installer action by 40-char SHA (per the Lab 3 rule)

### B.3: Demonstrate it caught a divergence

Deliberately break reproducibility in one of the two jobs (e.g. by setting a different `SOURCE_DATE_EPOCH` env var only in job A). Push. Confirm the third job goes **red**. Then fix it. Confirm green.

### B.4: Design questions

- h) **What's the difference between "reproducible on my laptop" and "reproducible in CI"** that makes the CI proof load-bearing for a security auditor?
- i) **Why two parallel jobs** instead of one job that runs `nix build` twice? What could a single-job two-build comparison miss?
- j) **`SOURCE_DATE_EPOCH`** is the canonical env var for forcing build timestamps. Where in your Nix flake would the timestamp normally leak in, and how does `dockerTools.buildImage` handle it?

### B.5: Document

In `submissions/lab11.md`:
- The workflow YAML (paste or link)
- Green CI run URL + log excerpt showing the two digests match
- Red CI run URL showing the digest-mismatch failure
- Design questions h, i, j answered

---

## How to Submit

1. `flake.nix` + `flake.lock` at the repo root
2. *(Bonus)* CI workflow + evidence of green and red runs
3. `submissions/lab11.md` covers all attempted tasks
4. PR from `feature/lab11` → course repo's `main`
5. Submit the PR URL via Moodle

---

## Acceptance Criteria

### Task 1 (4 pts)
- ✅ Flake builds QuickNotes via `nix build .#quicknotes`
- ✅ `./result/bin/quicknotes` runs and serves `/health`
- ✅ Two independent builds produce **identical** store hashes
- ✅ `flake.lock` committed
- ✅ Design questions a-d answered

### Task 2 (4 pts)
- ✅ `nix build .#docker` produces an OCI image, loadable via `docker load`
- ✅ Two independent builds produce identical SHA-256 tarball digests
- ✅ Comparison with non-reproducible Lab 6 image documented
- ✅ Design questions e, f, g answered

### Bonus Task (2 pts)
- ✅ CI workflow runs two parallel `nix build` jobs and asserts equal digests
- ✅ Both a green run AND a deliberately-broken red run exist
- ✅ Design questions h, i, j answered

---

## Rubric

| Task | Points | Criteria |
|------|-------:|----------|
| **Task 1** — Reproducible Go build | **4** | Flake correct, two-environment hash match, design questions |
| **Task 2** — Deterministic OCI image | **4** | Loadable image, two-environment digest match, vs-Lab 6 comparison |
| **Bonus** — CI-verified reproducibility | **2** | Two-parallel-jobs CI gate, green + red runs, design questions |
| **Total** | **10** | (bonus lab — contributes toward bonus-labs grade weight) |

> 📝 **Lab 11 itself is a bonus lab** — its full 10 pts go into the bonus-labs grade component (20% of the final grade; see the course [README](../README.md)).

---

## Common Pitfalls

- 🪤 **First build fails: `hash mismatch`** — that's Nix telling you the *correct* `vendorHash`. Paste the `got:` line, rerun
- 🪤 **`nix: command not found`** after install — open a new terminal so PATH refreshes
- 🪤 **Different hashes on two machines** — usually means `flake.lock` is not committed. The lockfile pins nixpkgs to a specific revision
- 🪤 **Out of disk** — Nix store grows. `nix store gc` reclaims unreferenced paths
- 🪤 **`nix build` requires internet on first run** — downloads pre-built artifacts from cache.nixos.org. Subsequent builds are mostly local
- 🪤 **`go.mod requires go >= 1.24` from `buildGoModule`** — your pinned nixpkgs ships an older default Go (e.g. `nixos-24.11` → Go 1.23). Fix it **in the flake**: pin `nixos-25.11` or newer, or use `buildGo124Module` / `buildGoModule.override { go = pkgs.go_1_24; }`. Don't downgrade `app/go.mod` — the app source is not yours to edit
- 🪤 **Installer or build times out on `install.determinate.systems`** — the host may be unreachable from your network even when a plain `curl -I` returns 200. Check from the *same terminal* where you run nix (a browser VPN does not cover WSL2 traffic): `curl -I https://install.determinate.systems` vs `curl -I https://cache.nixos.org/nix-cache-info`. Fall back to the official nixos.org installer (different CDN); builds themselves only need cache.nixos.org and github.com. If cache.nixos.org is also blocked, use a mirror substituter: `--option substituters "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"`
- 🪤 **WSL2 multi-user Nix is finicky** — use the Determinate installer; or single-user on WSL2

---

## Guidelines

- The reproducibility proof is the deliverable; the flake is just how you got there
- Pin everything: nixpkgs revision (via `flake.lock`), `vendorHash`, Go version
- For "two independent environments" the easiest path is `docker run --rm -it -v "$PWD:/repo" -w /repo nixos/nix bash`
- Once you have this, the natural next step is Cachix (shared binary cache) — out of scope but worth a follow-up project

---

## Resources

- 📕 [Nix Pills](https://nixos.org/guides/nix-pills/) — canonical intro
- 📕 [Zero to Nix](https://zero-to-nix.com/)
- 📗 [NixOS & Flakes Book](https://nixos-and-flakes.thiscute.world/)
- 🎥 [Domen Kožar — *Boost your dev env with Nix*](https://www.youtube.com/watch?v=BdF6w3LkkdU)
- 📝 [Reproducible Builds project](https://reproducible-builds.org/)
- 📝 [Eelco Dolstra — original Nix paper (PhD thesis, 2004)](https://edolstra.github.io/pubs/phd-thesis.pdf)
