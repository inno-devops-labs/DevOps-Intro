# Lab 6 — Containers: Dockerize QuickNotes

Host: Windows 11 + Docker **29.1.2**. Files:
[`app/Dockerfile`](../app/Dockerfile), [`compose.yaml`](../compose.yaml).

---

## Task 1 — Multi-Stage Dockerfile, ≤ 25 MB

### What the Dockerfile does

Two stages: a `golang:1.24` **builder** that compiles a static, stripped binary,
and a `gcr.io/distroless/static:nonroot` **runtime** that carries only the binary,
`seed.json`, and a nonroot-owned `/data`.

| Requirement | How |
|-------------|-----|
| Multi-stage | `builder` + `runtime` |
| Builder pinned | `golang:1.24` |
| Runtime base | `gcr.io/distroless/static:nonroot` (no shell, no apt) |
| Static binary | `CGO_ENABLED=0` |
| Stripped / reproducible | `-ldflags='-s -w' -trimpath` |
| Nonroot | `USER nonroot:nonroot` (uid 65532) |
| Exec entrypoint + EXPOSE | `ENTRYPOINT ["/quicknotes"]`, `EXPOSE 8080` |
| Cache-friendly order | `COPY go.mod` + `go mod download` **before** `COPY . .` |

### Build + verify (real output)

```text
$ docker images quicknotes:lab6 --format '{{.Repository}}:{{.Tag}}  {{.Size}}'
quicknotes:lab6  8.56MB                       # ≤ 25 MB ✅

$ docker inspect quicknotes:lab6 --format '{{.Config.User}} | {{json .Config.ExposedPorts}} | {{json .Config.Entrypoint}}'
nonroot:nonroot | {"8080/tcp":{}} | ["/quicknotes"]

$ docker run -d -p 8080:8080 quicknotes:lab6 ; curl -s :8080/health
{"notes":4,"status":"ok"}                     # 200
# POST /notes -> 201, GET /notes shows the new note
```

Base-image comparison: builder `golang:1.24` is **894 MB**, the distroless runtime
base is **2.21 MB**, and our final image is **8.56 MB** (binary + seed + /data).
Multi-stage threw away ~890 MB of toolchain.

### 1.2 Design questions

**a) Why does layer order matter? (`COPY . .` early vs `go.mod` first)**

Each Dockerfile instruction is a cached layer keyed on its inputs. With
`COPY . . && go mod download && go build`, *any* source edit changes the `COPY . .`
layer, which invalidates everything after it — so `go mod download` re-runs on
every rebuild. With `COPY go.mod ./ && go mod download && COPY . . && go build`,
the download layer is keyed only on `go.mod`/`go.sum`; a source-only edit reuses
the cached dependencies and only re-runs the build. On a rebuild after touching a
`.go` file, strategy A pays the dependency download again (cache miss), strategy B
skips it (cache hit). *Caveat for this repo:* QuickNotes has zero external
dependencies, so `go mod download` is near-instant and the absolute saving here is
small — but the ordering is still correct and on a real dependency tree it's the
difference between a sub-second rebuild and re-pulling hundreds of modules.

**b) Why `CGO_ENABLED=0`?**

It forces a fully static binary with no libc / dynamic-linker dependency. The
default `CGO_ENABLED=1` links against the host's glibc dynamically. `distroless/
static` deliberately contains **no libc and no dynamic linker (ld.so)**, so a
dynamically-linked binary fails to start — the kernel can't find the ELF
interpreter and you get `no such file or directory` (on the binary that visibly
exists). Forgetting the flag = a container that won't run.

**c) What is `gcr.io/distroless/static:nonroot`?**

A minimal runtime image containing essentially only: CA certificates, `/etc/passwd`
with a `nonroot` user (uid 65532), timezone data, and a `/tmp` dir. What it
*doesn't* have is the point — **no shell, no package manager, no busybox, no
libc, no coreutils**. That shrinks the attack surface and, crucially, the CVE
surface: there are no OS packages to be vulnerable. Trivy confirms **0 HIGH/
CRITICAL in the OS layer** (see Bonus).

**d) `-ldflags='-s -w'` and `-trimpath`?**

`-s` drops the symbol table, `-w` drops DWARF debug info — together they shrink
the binary and remove most of what a debugger/symbolizer would use. `-trimpath`
strips absolute build-machine file paths from the binary, replacing them with
module-relative paths. The cost: `-s -w` makes post-mortem debugging and
profiling with symbols much harder (no `delve`, degraded stack symbolization);
`-trimpath` removes local path info that some debug workflows rely on. The payoff
is a smaller, **reproducible** binary that doesn't leak the build host's directory
layout — the right trade for a shipped image.

---

## Task 2 — Compose + Healthcheck + Persistent Volume

### Persistence test (real output)

```text
$ docker compose up --build -d ; docker compose ps --format '{{.Health}}'
healthy

$ curl -XPOST -d '{"title":"durable","body":"survive a restart"}' :8080/notes      # 201
present after create:        1

$ docker compose down ; docker compose up -d
present after down + up:     1     # ✅ survived (named volume kept)

$ docker compose down -v ; docker compose up -d
present after down -v + up:  0     # gone (volume destroyed)
```

### 2.2 Design questions

**e) Distroless has no shell — how do you healthcheck it?**

I made the QuickNotes binary **dual-mode**: `quicknotes healthcheck` does an
in-process HTTP GET to `/health` and exits `0` (healthy) or `1` (unhealthy). The
Compose healthcheck re-invokes the only binary in the image in exec form:
`test: ["CMD", "/quicknotes", "healthcheck"]`. No shell, no `wget`, no sidecar.
This is the lab's "use a binary that's already in the image" option, and it's the
cleanest — verified: `docker compose ps` reports **healthy**.

**f) Why does the named volume survive `docker compose down`? What destroys it?**

`docker compose down` removes containers and the default network, but **named
volumes are separate objects with their own lifecycle** — they are intentionally
left intact so data outlives container churn, and re-attach on the next `up`.
What destroys it: `docker compose down -v` (or `docker volume rm
quicknotes-data`). The test above shows exactly this: the note survives `down +
up` and disappears only after `down -v`.

**g) `depends_on` without `condition: service_healthy`?**

Plain `depends_on: [x]` only waits for container `x` to be **started** (its
process launched / created), *not* for it to be **ready** to serve. The bug:
the dependent service can come up and start making requests before `x` is
actually accepting connections — e.g. an app querying a database that has
"started" but isn't listening yet, giving intermittent connection-refused races
on boot. `condition: service_healthy` makes Compose wait for `x`'s healthcheck to
pass first.

---

## Bonus — The 6 Security Defaults

### Hardened `services.quicknotes` block

```yaml
read_only: true            # 4. read-only root filesystem
tmpfs:
  - /tmp                   #    writable scratch (the /data named volume stays writable)
cap_drop:
  - ALL                    # 3. drop every Linux capability (QuickNotes needs none)
security_opt:
  - no-new-privileges:true # 5. block setuid privilege escalation
# 1. USER nonroot  + 2. distroless base  come from app/Dockerfile
# 6. Trivy scan below
```

### Verification (real output)

| # | Default | Command | Result |
|---|---------|---------|--------|
| 1 | `USER nonroot` | `inspect ... .Config.User` | `nonroot:nonroot` |
| 2 | No shell | `compose exec quicknotes sh` | `exec: "sh": executable file not found` (fails ✅) |
| 3 | Caps dropped | `inspect ... .HostConfig.CapDrop` | `[ALL]` |
| 4 | Read-only root | `inspect ... .HostConfig.ReadonlyRootfs` | `true` |
| 5 | no-new-privileges | `inspect ... .HostConfig.SecurityOpt` | `[no-new-privileges:true]` |

All five enforced while the service still reports **healthy** and serves
`/health` — read-only root + dropped caps don't break QuickNotes because it only
writes to the `/data` volume (and `/tmp` tmpfs).

### Trivy scan

```text
$ docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
    aquasec/trivy:0.59.1 image --severity HIGH,CRITICAL --no-progress quicknotes:lab6

quicknotes:lab6 (debian 13.5)      Total: 0  (HIGH: 0, CRITICAL: 0)   # OS layer — clean
quicknotes (gobinary)              Total: 12 (HIGH: 12, CRITICAL: 0)  # all Go stdlib
```

The **OS layer has zero HIGH/CRITICAL** — exactly the distroless payoff (no OS
packages = nothing to patch). The 12 HIGH are all in the **Go standard library**
compiled into the binary (e.g. `net/url`, `net/mail`, `net/http/httputil`),
fixed in Go `1.25.8 / 1.26.1`. The lab pins the builder to Go `1.24` (whose
latest patch `1.24.13` still predates those fixes), so they remain; in a real
pipeline you'd bump the builder's Go minor version to clear them. Distroless
fixed the base image; the binary's stdlib is a separate supply-chain axis.

### Most security per line of YAML

**`cap_drop: [ALL]`** — one line strips every Linux capability the container
would otherwise inherit (~14 by default, including `CAP_NET_RAW`,
`CAP_CHOWN`, `CAP_SETUID`…), collapsing a huge slice of the kernel attack surface
that container escapes typically abuse. QuickNotes needs none, so the cost is
zero. Runner-up is `read_only: true`, which neutralizes persistence/tampering on
the root filesystem in one line — but `cap_drop: ALL` removes the most latent
privilege for the least YAML.
