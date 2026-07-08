# Lab 11 submission

**Host:** Apple Silicon Mac (no local Nix). **Build env:** University VM + Determinate Nix 2.34.7. **nixpkgs:** `nixos-24.11` (see `flake.lock`).

---

## Task 1 — Reproducible Go build

### `flake.nix`

See [`flake.nix`](../flake.nix) · lockfile [`flake.lock`](../flake.lock)

Uses **`buildGoModule`** with `vendorHash = null` (no third-party Go modules). `postPatch` rewrites `go 1.24` → `go 1.23` inside the sandbox because `nixos-24.11` ships Go 1.23.

### Build log excerpt

[`attachments/lab11/nix-build-quicknotes.log`](attachments/lab11/nix-build-quicknotes.log)

```text
quicknotes> ok          quicknotes      0.009s
```

### Reproducibility proof (store hashes)

Two independent checkouts on **University VM** (`/root/lab11-work/DevOps-Intro` and `/root/lab11-fresh`):

| Environment | `nix-store --query --hash` |
|-------------|----------------------------|
| A | `sha256:1xh9z7n1ax8hbissdcr7ivj2zcx56fhb1aj4i1l7hs5axq29xrym` |
| B | `sha256:1xh9z7n1ax8hbissdcr7ivj2zcx56fhb1aj4i1l7hs5axq29xrym` |

### Runtime proof

```bash
ADDR=:18080 DATA_PATH=/tmp/qn-notes.json SEED_PATH=$PWD/app/seed.json ./result/bin/quicknotes &
curl -fsS http://127.0.0.1:18080/health
# {"notes":4,"status":"ok"}
```

### Design questions (a–d)

**a) Why isn't `go build` bit-identical across machines?**

Build IDs embed timestamps and VCS metadata; module cache paths differ; `-trimpath` behavior varies; floating `go` toolchain versions change compiler output. Two laptops with the same Git SHA can still produce different ELF hashes.

**b) What is `vendorHash`?**

SHA-256 over the output of `go mod vendor` (the `vendor/` tree). If wrong, Nix fails with `hash mismatch` and prints the correct `got:` value. With `vendorHash = null`, Nix skips the check — fine for hacking, useless for reproducibility.

**c) Why is `flake.lock` critical?**

It pins **every flake input** (nixpkgs revision, flake-utils, etc.) to exact commits. Delete it before the second build and Nix may fetch a newer nixpkgs → different Go compiler → different binary hash.

**d) `buildGoModule` vs `buildGoApplication`**

`buildGoModule` expects `go.mod`/`go.sum` and vendors deps (`vendorHash`). `buildGoApplication` is for projects already using a checked-in `vendor/` tree or simpler layouts. **Pick `buildGoModule`** for QuickNotes — standard for Go modules, explicit vendor pinning.

---

## Task 2 — Deterministic OCI image

### Docker output in flake

```nix
packages.docker = pkgs.dockerTools.buildImage { ... };
```

`nix build .#docker` → OCI tarball at `result` (load with `docker load < result`).

### Image digest proof

[`attachments/lab11/nix-docker-digests.txt`](attachments/lab11/nix-docker-digests.txt)

| Environment | `sha256sum` (OCI tarball) |
|-------------|---------------------------|
| A | `28db2a32677bb3eb3c133ec33072ff4ad4350ea67d4445b30c422a349bd24874` |
| B | `28db2a32677bb3eb3c133ec33072ff4ad4350ea67d4445b30c422a349bd24874` |

### vs Lab 6 Dockerfile (non-reproducible)

```bash
docker build --no-cache -t qn-lab6:run1 ./app
docker build --no-cache -t qn-lab6:run2 ./app
docker images --no-trunc qn-lab6
```

| Tag | Image ID |
|-----|----------|
| run1 | `sha256:01073da0688e9b8a22df65b857da54bf64d4b7fda60234cc7d821485e8da3ce8` |
| run2 | `sha256:fbcdbd2e78cedf9b7e904f11b561c388b28abd5f75e396baa851a102aca0df12` |

Same Dockerfile + same source, **different digests** — non-reproducible layer metadata.

### Image size

| Build | Size |
|-------|-----:|
| Nix `dockerTools.buildImage` | 2.9 MB |
| Lab 6 distroless Dockerfile | ~16 MB |

### Design questions (e–g)

**e) What does `docker build` do that Nix doesn't?**

Docker layers embed creation timestamps, may include non-deterministic file ordering, and `FROM` pulls mutable tags. `dockerTools.buildImage` builds from a fixed store path closure — same inputs → same tarball bytes.

**f) What can an auditor prove with reproducible images?**

Anyone can rebuild from source + flake.lock and verify the digest matches the published image — supply-chain integrity without trusting only a signature on opaque bits.

**g) Trade-off vs `docker build`**

Nix buys reproducibility and pinned toolchains at the cost of learning curve, larger store, and slower cold builds. Docker wins on familiarity, ecosystem, and incremental layer cache for most teams.

---

## Bonus — CI-verified reproducibility

### Workflow

[`.github/workflows/nix-repro.yml`](../.github/workflows/nix-repro.yml) — two parallel `nix build .#docker` jobs; `nix-repro-ok` compares `sha256sum` outputs.

### CI runs

- **Green:** <!-- Actions URL — digests match -->
- **Red (intentional `SOURCE_DATE_EPOCH` break in job A):** <!-- Actions URL -->

### Design questions (h–j)

**h) Laptop vs CI reproducibility**

CI proves any reviewer can trigger the same check on ephemeral runners — not just the author's machine. Auditors trust automation + logs, not screenshots.

**i) Why two parallel jobs?**

A single job running twice shares runner state, store paths, and timing — could hide environment leaks. Independent runners start from the same checkout with empty stores.

**j) `SOURCE_DATE_EPOCH`**

Timestamps leak into archive metadata and build IDs. `dockerTools.buildImage` respects `SOURCE_DATE_EPOCH` for deterministic layer times; mismatched epoch between jobs → digest mismatch (used for the red CI demo).

---

## Artifacts

| Path | Description |
|------|-------------|
| `flake.nix` / `flake.lock` | Reproducible Go + OCI outputs |
| `.github/workflows/nix-repro.yml` | CI digest gate |
| `submissions/attachments/lab11/` | Build logs, hash captures |
