# Lab 6 — Containers: Dockerize QuickNotes

Built and tested for real with Docker 29.1.3 + Compose v2.40. My Windows host
already runs Docker Desktop on `:8080`, so I ran the engine inside WSL2 (Ubuntu
24.04) and published the compose service on host port 18080 for the live tests —
the committed `compose.yaml` still defaults to 8080 (`${QN_HOST_PORT:-8080}:8080`).

Files: [`app/Dockerfile`](../app/Dockerfile), [`compose.yaml`](../compose.yaml).

---

## Task 1 — Multi-stage Dockerfile, ≤ 25 MB

The Dockerfile is multi-stage: a `golang:1.24` builder that produces a static,
stripped binary, and a `gcr.io/distroless/static:nonroot` runtime with no shell
or package manager. `go.mod` is copied before the source so the dependency layer
stays cached. A tiny static Go probe binary is built alongside the app to act as
the healthcheck (distroless has nothing to curl/wget with).

**Size — `docker images` (requirement: ≤ 25 MB):**
```
REPOSITORY:TAG    SIZE
quicknotes:lab6   22.7MB
```
For comparison, the builder base is `golang:1.24 = 1.32GB` — the multi-stage build
ships ~1.5% of that.

**`docker inspect` (User / ExposedPorts / Entrypoint / Env):**
```json
{
  "User": "nonroot:nonroot",
  "ExposedPorts": { "8080/tcp": {} },
  "Entrypoint": ["/qn"],
  "Env": ["...", "ADDR=:8080", "DATA_PATH=/data/notes.json", "SEED_PATH=/seed.json"]
}
```

**Run + health (from the host):**
```
GET /health -> {"notes":4,"status":"ok"}
container health: healthy
```

### Design questions

**a) Why does layer order matter? (measured rebuild times)**
Measured on this Dockerfile:

| Build | Time |
|-------|-----:|
| Clean build (`--no-cache`) | 22.76 s |
| Rebuild, no change (full cache hit) | 3.11 s |
| Rebuild after a source change (go.mod layer stays cached) | 22.62 s |

Docker caches each instruction layer and reuses it until something it depends on
changes. By copying `go.mod` and running `go mod download` *before* `COPY . .`,
a source-only change can't invalidate the dependency layer — the
`COPY go.mod && download` strategy keeps deps cached, while the naive
`COPY . . && download && build` re-downloads everything on any file change.
Here the two strategies come out almost equal (22.6 s vs 22.8 s) for an honest
reason: QuickNotes has **zero third-party dependencies**, so `go mod download`
costs nothing and the cached layer saves nothing — the ~22 s is the Go *compile*,
which re-runs on any source change either way. On a real project with a big
`go.sum`, the dependency layer is the expensive one, and that's where correct
ordering turns a multi-minute rebuild into seconds (as the no-change cache hit at
3.11 s hints).

**b) Why `CGO_ENABLED=0`?** It forces a fully static binary with Go's pure-Go
implementations (net, crypto) instead of linking libc. `distroless/static` has no
dynamic linker and no shared libraries, so a CGO-enabled (dynamically linked)
binary would build fine but **crash at container start** with something like
`no such file or directory` / missing `ld-linux` — the kernel can't find the
loader the binary asks for. Static = nothing to link against at runtime.

**c) What is `gcr.io/distroless/static:nonroot`?** A ~2 MB base that contains
only what a static binary needs at runtime: CA certificates, `/etc/passwd` with a
`nonroot` user (UID 65532), timezone data, and `/tmp` — and nothing else. No
shell, no `apt`, no busybox, no libc. Because there are no OS packages, there's
almost no CVE surface: Trivy reported **0 HIGH/CRITICAL OS vulnerabilities** for
the base (see Bonus). Fewer things in the image = fewer things to patch and fewer
ways in.

**d) `-ldflags='-s -w'` and `-trimpath`.** `-s` drops the symbol table and `-w`
drops DWARF debug info, shrinking the binary; the cost is you can't get symbolized
stack traces or run a debugger against it. `-trimpath` removes absolute build-machine
paths (like `/home/me/go/...`) from the binary, which makes builds reproducible and
avoids leaking local paths; the cost is panic traces show trimmed module paths
instead of full local paths. Both are standard for release/container builds.

---

## Task 2 — Compose + Healthcheck + Persistent Volume

`compose.yaml` builds from `./app`, tags `quicknotes:lab6`, mounts a named volume
at `/data`, sets `ADDR`/`DATA_PATH`/`SEED_PATH`, declares a healthcheck, and uses
`restart: unless-stopped`.

**Persistence test (on host port 18080):**
```
create a note  -> {"id":5,"title":"durable",...}
grep durable                       -> durable      # present
docker compose down  (keep volume)
docker compose up    -> grep durable -> durable    # SURVIVED a restart
docker compose down -v  (destroy volume)
docker compose up    -> grep durable -> GONE       # volume destroyed
```

### Design questions

**e) Distroless has no shell — how do you healthcheck it?** A `CMD-SHELL`
healthcheck (and `curl`/`wget` ones) can't work because there's no shell or those
binaries in the image. My choice: **ship a tiny static Go probe binary** built in
the same builder stage, copied to `/healthcheck`, and called with the exec-form
`HEALTHCHECK CMD ["/healthcheck"]`. It does an HTTP GET to `127.0.0.1:8080/health`
and exits 0/1. Verified: the container reports `healthy`. (Other options I
rejected: a wget-only debug base — defeats the point of distroless; or relying on
Docker only checking the process is alive — that doesn't catch a hung server.)

**f) Why does the named volume survive `docker compose down`?** `down` removes the
containers and the default network, but **named volumes are deliberately left
alone** — they're treated as data you want to keep. The note is stored in the
`quicknotes-data` volume, not the container's writable layer, so it's still there
after `down` + `up`. What destroys it: `docker compose down -v` (or
`docker volume rm quicknotes-data`) — shown above, the note was gone afterward.

**g) `depends_on` without `condition: service_healthy`.** Plain `depends_on` only
waits for the dependency container to **start** (be created and running), not for
the app inside to be **ready**. So a dependent service can start connecting while
the dependency is still booting and not yet accepting requests — a startup race
that shows up as flaky "connection refused" on cold starts. `condition:
service_healthy` makes Compose wait for the healthcheck to pass first.

---

## Bonus — The 6 Security Defaults (all applied + verified)

| # | Default | Evidence |
|---|---------|----------|
| 1 | `USER nonroot` | `docker inspect ... .Config.User` → `nonroot:nonroot` |
| 2 | Distroless base (no shell) | `docker compose exec quicknotes sh` → `exec: "sh": executable file not found in $PATH` |
| 3 | Drop all capabilities | `.HostConfig.CapDrop` → `[ALL]` |
| 4 | Read-only root + tmpfs | `.HostConfig.ReadonlyRootfs` → `true`, `Tmpfs` → `map[/tmp:]` |
| 5 | `no-new-privileges` | `.HostConfig.SecurityOpt` → `[no-new-privileges:true]` |
| 6 | Trivy scan | see below |

**Trivy (`--severity HIGH,CRITICAL`):**
```
quicknotes:lab6 (debian 13.5)        Total: 0 (HIGH: 0, CRITICAL: 0)   # distroless OS packages
/qn  (gobinary)                      Total: 12 (HIGH: 12, CRITICAL: 0) # Go stdlib
```
Honest reading: the **distroless base contributes zero OS-package CVEs** — that's
the whole point of a minimal base. The 12 HIGH are all in the **Go standard
library compiled into the binary** (net/http ReverseProxy, MIME-header DoS, etc.),
flagged because the task pins the builder to `golang:1.24`; they're fixed in Go
1.25.11 / 1.26.4, so bumping the toolchain would clear them — but the lab requires
the builder pinned to 1.24, so I kept it and documented the trade-off. The lesson:
distroless removes the OS attack surface, but your application's own toolchain
version is still your responsibility.

---

## Summary

| Task | Result |
|------|--------|
| 1 — Dockerfile ≤ 25 MB | multi-stage, distroless nonroot, static stripped binary; `docker images` = **22.7 MB**; healthy `200` |
| 2 — Compose + volume | named volume survives `down`, dies on `down -v`; Go-probe healthcheck → `healthy` |
| Bonus — 6 defaults | nonroot, distroless, `cap_drop ALL`, read-only+tmpfs, no-new-privileges, Trivy (0 OS CVEs) — all verified |
