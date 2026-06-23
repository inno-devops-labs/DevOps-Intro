# Lab 6 — Containers: Dockerize QuickNotes

Mahmoud Hassan (`selysecr332`)  
**Environment:** Windows 11 + Docker 29.x

---

## Task 1 — Multi-stage Dockerfile (≤ 25 MB)

### Dockerfile

See [`app/Dockerfile`](../app/Dockerfile).

### `docker images quicknotes:lab6`

```text
IMAGE             ID             DISK USAGE   CONTENT SIZE
quicknotes:lab6   4a2a4575e34a       22.7MB         5.71MB
```

### `docker inspect` excerpt (User, ExposedPorts, Entrypoint)

```text
$ docker inspect quicknotes:lab6 --format "User={{.Config.User}} Entrypoint={{.Config.Entrypoint}}"
User=nonroot Entrypoint=[/quicknotes]
```

### Builder base image size (comparison)

```text
quicknotes:lab6          22.7MB
golang:1.24.5-alpine    394MB
```

(~17× smaller runtime image than builder base)

### Task 1 verification

```text
$ Invoke-RestMethod http://127.0.0.1:8080/health
{"notes":4,"status":"ok"}
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
Note: `vol-init` (busybox) runs once to `chown` the named volume for UID 65532 — required because Docker creates new volumes as root and distroless runs as `nonroot`.

### Persistence test (present → down → up → present → down -v → up → absent)

```text
# POST durable note
{"id":5,"title":"durable","body":"survive a restart",...}

# after docker compose down && docker compose up -d (no -v)
{"id":5,"title":"durable","body":"survive a restart",...}   ✅ still present

# after docker compose down -v && docker compose up -d
durable absent (expected)   ✅ volume destroyed
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
  quicknotes:
    cap_drop:
      - ALL
    read_only: true
    tmpfs:
      - /tmp
    security_opt:
      - no-new-privileges:true
```

(Dockerfile: `USER nonroot`, `gcr.io/distroless/static:nonroot` base)

### Verification outputs (B.2)

```text
USER: nonroot
exec sh: exec: "sh": executable file not found in $PATH   ✅ no shell
CapDrop: [ALL]
SecurityOpt: [no-new-privileges:true]
ReadonlyRootfs: true
```

### Trivy summary

```text
Distroless base layer: Total: 0 (HIGH: 0, CRITICAL: 0)
Embedded Go stdlib (v1.24.5): Total: 16 (HIGH: 15, CRITICAL: 1)
```

Distroless base is clean; remaining findings are in the **compiled Go stdlib** (fixed in Go 1.24.12+). Lab 9 will wire Trivy into CI.

### Which default gives the most security per line of YAML?

`read_only: true` plus `cap_drop: [ALL]` — two lines that block most container escape and persistence paths. `read_only` prevents runtime package installs and config tampering; dropping all capabilities removes the Linux privilege escalation surface. Distroless + `nonroot` are Dockerfile-level but equally high leverage.

---

## Lab 6 completion checklist

### Task 1 (6 pts)

- [x] Multi-stage Dockerfile, ≤ 25 MB, nonroot, distroless
- [x] `docker run` serves `/health`
- [x] Design questions a–d answered
- [x] Build outputs pasted

### Task 2 (4 pts)

- [x] `compose.yaml` with volume, healthcheck, env, restart
- [x] Persistence test demonstrated
- [x] Design questions e–g answered

### Bonus (2 pts)

- [x] All 6 defaults applied and verified
- [x] Trivy scan documented

### Submission

- [x] Course PR (`feature/lab6` → `inno-devops-labs/main`)  
  **https://github.com/inno-devops-labs/DevOps-Intro/pull/1157**
- [x] Fork PR (`feature/lab6-fork` → `selysecr332/main`)  
  **https://github.com/selysecr332/DevOps-Intro/pull/7**
- [x] Both URLs on Moodle
