# Lab 6 — Containers: Dockerize QuickNotes

Mahmoud Hassan (`selysecr332`)  
**Environment:** Windows 11 + Docker 29.x

---

## Task 1 — Multi-stage Dockerfile (≤ 25 MB)

### Dockerfile

See [`app/Dockerfile`](../app/Dockerfile).

### `docker images quicknotes:lab6`

```text
<!-- paste docker images output after build -->
```

### `docker inspect` excerpt (User, ExposedPorts, Entrypoint)

```text
<!-- paste docker inspect quicknotes:lab6 --format or jq excerpt -->
```

### Builder base image size (comparison)

```text
<!-- paste docker images golang:1.24.5-alpine -->
```

### Task 1 verification

```text
<!-- paste curl /health from docker run -->
```

### Design questions (Task 1)

**a) Why does layer-order matter?**

`COPY go.mod` + `go mod download` before `COPY . .` keeps the dependency layer cached when only source changes. With `COPY . .` first, any file edit invalidates `go mod download` and forces a full module fetch + rebuild. On this project (no external deps) the win is small; the pattern matters once `go.sum` grows.

**b) Why `CGO_ENABLED=0`?**

Produces a fully static binary with no dynamic linker dependency. `gcr.io/distroless/static` has no `libc.so` loader — a CGO-linked binary fails at startup with `no such file or directory` (often misread as a missing binary).

**c) What is `gcr.io/distroless/static:nonroot`?**

Contains CA certs, `/etc/passwd` entry for UID 65532 (`nonroot`), timezone data, and **only** what a static binary needs. No shell, no `apt`, no package manager. Fewer packages → smaller attack surface and far fewer CVEs than `ubuntu` or `alpine` with a shell.

**d) `-ldflags='-s -w'` and `-trimpath`?**

`-s -w` strips the symbol table and DWARF debug info (smaller binary; harder to debug with `dlv`). `-trimpath` removes local filesystem paths from the binary for reproducible builds and cleaner stack traces in CI.

---

## Task 2 — Compose + healthcheck + volume

### `compose.yaml`

See [`compose.yaml`](../compose.yaml) at repo root.

### Persistence test (present → down → up → present → down -v → up → absent)

```text
<!-- paste 3-step test output -->
```

### Design questions (Task 2)

**e) Distroless has no shell. How do you healthcheck it?**

Strategy: **HTTP probe via a second static binary** (`/healthcheck`) built in the builder stage and copied into the runtime image. Compose runs `test: ["CMD", "/healthcheck"]`, which GETs `http://127.0.0.1:8080/health` and exits non-zero on failure — no shell, `curl`, or `wget` required in distroless.

**f) Why does `volumes: [quicknotes-data:/data]` survive `docker compose down`?**

Named volumes are managed by Docker outside the container lifecycle. `docker compose down` removes containers and networks but **not** named volumes unless you pass `-v`. `docker compose down -v` (or `docker volume rm`) destroys the data.

**g) `depends_on` without `condition: service_healthy`?**

Compose only waits for the **container to start**, not for the app inside to be ready. A dependent service can connect before QuickNotes listens on `:8080`, causing flaky startup races (relevant in Lab 8 when Prometheus scrapes QuickNotes).

---

## Bonus — 6 security defaults

### Hardened `compose.yaml` snippet

```yaml
# cap_drop, read_only, tmpfs, security_opt — see compose.yaml services.quicknotes
```

### Verification outputs (B.2)

```text
<!-- USER nonroot -->
<!-- exec sh fails -->
<!-- CapDrop [ALL] -->
<!-- read-only root test -->
<!-- SecurityOpt no-new-privileges -->
```

### Trivy summary

```text
<!-- paste trivy scan output -->
```

### Which default gives the most security per line of YAML?

_TODO after Trivy run — likely `read_only: true` + `cap_drop: ALL`._

---

## Lab 6 completion checklist

### Task 1 (6 pts)

- [ ] Multi-stage Dockerfile, ≤ 25 MB, nonroot, distroless
- [ ] `docker run` serves `/health`
- [ ] Design questions a–d answered
- [ ] Build outputs pasted

### Task 2 (4 pts)

- [ ] `compose.yaml` with volume, healthcheck, env, restart
- [ ] Persistence test demonstrated
- [ ] Design questions e–g answered

### Bonus (2 pts)

- [ ] All 6 defaults applied and verified
- [ ] Trivy scan documented

### Submission

- [ ] Course PR (`feature/lab6` → `inno-devops-labs/main`)
- [ ] Fork PR (`feature/lab6-fork` → `selysecr332/main`)
- [ ] Moodle URLs
