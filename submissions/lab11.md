# Lab 11 — Reproducible Builds with Nix

Mahmoud Hassan (`selysecr332`)  
**Environment:** Windows 11 + WSL2/Docker + Nix Flakes

---

## Task 1 — Reproducible Go build

### flake.nix

See [`flake.nix`](../flake.nix) at repo root (committed with [`flake.lock`](../flake.lock)).

**Builder choice:** `buildGoModule` — integrates `go mod download`/vendor hashing into Nix; `buildGoApplication` is the newer flake-centric wrapper but `buildGoModule` is well-documented and sufficient for a single-module app with no external deps.

### Build log excerpt

```text
<!-- paste: nix build .#quicknotes -->
```

### Reproducibility proof (store hashes)

```text
# environment A
<!-- nix-store --query --hash $(readlink result) -->

# environment B (fresh clone / nixos/nix container)
<!-- nix-store --query --hash $(readlink result) -->
```

### Runtime proof

```text
<!-- ./result/bin/quicknotes & curl localhost:8080/health -->
```

### Design questions (Task 1)

**a) Why doesn't `go build` produce bit-identical outputs on two machines?**

<!-- answer -->

**b) `vendorHash` is a SHA over what? What if `vendorHash = null`?**

<!-- answer -->

**c) Why is `flake.lock` the most important file for reproducibility?**

<!-- answer -->

**d) `buildGoModule` vs `buildGoApplication`?**

<!-- answer -->

---

## Task 2 — Deterministic OCI image

### docker output snippet

```nix
<!-- paste dockerTools.buildImage section from flake.nix -->
```

### Image size comparison

| Image | Size |
|-------|-----:|
| Nix (`nix build .#docker`) | <!-- MB --> |
| Lab 6 Docker (`docker build ./app`) | <!-- MB --> |

### Nix image digest proof

```text
# environment A
<!-- sha256sum result -->

# environment B
<!-- sha256sum result -->
```

### Lab 6 non-reproducible comparison

```text
$ docker build --no-cache -t qn-lab6:run1 ./app
$ docker build --no-cache -t qn-lab6:run2 ./app
$ docker images --no-trunc qn-lab6
<!-- paste two different digests -->
```

### Design questions (Task 2)

**e) What does `docker build` do that introduces non-determinism?**

<!-- answer -->

**f) What can an auditor prove with a reproducible image vs signed-only?**

<!-- answer -->

**g) Trade-off of Nix reproducibility vs `docker build` default?**

<!-- answer -->

---

## Bonus — CI-verified reproducibility

### Workflow

[`.github/workflows/nix-repro.yml`](../.github/workflows/nix-repro.yml)

### CI evidence

| Run | URL |
|-----|-----|
| Green (digests match) | <!-- --> |
| Red (deliberate mismatch) | <!-- --> |

### Design questions (Bonus)

**h) Laptop vs CI reproducibility?**

<!-- answer -->

**i) Why two parallel jobs instead of two builds in one job?**

<!-- answer -->

**j) `SOURCE_DATE_EPOCH` — where would timestamps leak?**

<!-- answer -->

---

## Lab 11 completion checklist

### Task 1 (4 pts)

- [ ] `nix build .#quicknotes` succeeds
- [ ] Binary runs; `/health` OK
- [ ] Two-environment store hash match
- [ ] `flake.lock` committed
- [ ] Design questions a–d

### Task 2 (4 pts)

- [ ] `nix build .#docker`; `docker load` works
- [ ] Two-environment tarball digest match
- [ ] Lab 6 digest mismatch documented
- [ ] Design questions e–g

### Bonus (2 pts)

- [ ] CI two-job digest gate + green + red runs
- [ ] Design questions h–j

### Submission

- [ ] Course PR (`feature/lab11` → `inno-devops-labs/main`)
- [ ] Fork PR
- [ ] Moodle URL
