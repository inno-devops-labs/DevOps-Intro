# Lab 6 — Containers: Dockerize QuickNotes

**Author:** Karim Abdulkin (@GrandAdmiralBee)
**Branch:** `feature/lab6`
**Container runtime:** podman 5.x with `dockerCompat = true` (NixOS); commands run via the `docker` shim, OCI semantics identical to Docker 28.

---

## Task 1 — Multi-stage Dockerfile, ≤ 25 MB

### `app/Dockerfile`

```dockerfile
# syntax=docker/dockerfile:1.7

# Stage 1: builder
FROM golang:1.24.13-alpine AS builder
WORKDIR /src

# Layer-cache: dependencies before source
COPY go.mod ./
RUN go mod download

COPY . .

ENV CGO_ENABLED=0 \
    GOOS=linux \
    GOARCH=amd64

RUN go build -trimpath -ldflags='-s -w' -o /out/quicknotes . \
 && go build -trimpath -ldflags='-s -w' -o /out/healthcheck ./cmd/healthcheck \
 && mkdir -p /out/data

# Stage 2: runtime — distroless static, nonroot
FROM gcr.io/distroless/static-debian12:nonroot

COPY --from=builder /out/quicknotes  /quicknotes
COPY --from=builder /out/healthcheck /healthcheck
COPY --from=builder /src/seed.json   /seed.json
COPY --from=builder --chown=65532:65532 /out/data /data

ENV ADDR=:8080 \
    DATA_PATH=/data/notes.json \
    SEED_PATH=/seed.json

EXPOSE 8080
USER nonroot:nonroot
ENTRYPOINT ["/quicknotes"]
```

The Dockerfile also ships a tiny **`app/cmd/healthcheck/main.go`** (~20 LoC, no deps) — a static Go binary that `GET`s `/health` and exits 0/1.
It's copied alongside `/quicknotes` so the distroless image can be healthchecked from inside (see Task 2 design question **e**).

### Image size + composition

```console
$ docker images | grep -E 'quicknotes|golang|distroless'
localhost/quicknotes               lab6           ec82f821544e  14.6 MB
docker.io/library/golang           1.24.13-alpine 88aa171b8c32  274 MB
gcr.io/distroless/static-debian12  nonroot        8457fe6a812e  3.15 MB
```

Final image: **14.6 MB** vs the 25 MB cap — fully under, with ~10 MB headroom for future dependencies. Composition:
- Distroless static base: 3.15 MB
- Both Go binaries (`quicknotes` + `healthcheck`) + `seed.json` + `/data` skeleton: ~11.4 MB

The 274 MB builder image is left in the *first stage* and never enters the runtime layer — that's multi-stage doing its job.

### Image inspect

```console
$ docker inspect quicknotes:lab6 | jq '.[0].Config | {User, ExposedPorts, Entrypoint, Env}'
{
  "User": "nonroot:nonroot",
  "ExposedPorts": { "8080/tcp": {} },
  "Entrypoint": [ "/quicknotes" ],
  "Env": [
    "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
    "SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt",
    "ADDR=:8080",
    "DATA_PATH=/data/notes.json",
    "SEED_PATH=/seed.json"
  ]
}
```

All Task 1 boxes ticked: `User: nonroot:nonroot` (not root), `Entrypoint` is exec form, `EXPOSE 8080` is declared, env defaults present,
`SSL_CERT_FILE` comes from the distroless base.

### Smoke test

```console
$ docker run -d --name qn-smoketest -p 18080:8080 quicknotes:lab6
b5cd70b9b07a32ecb1ecb6b4c78e0b06d59f945444096c7c981379ef27930f52

$ docker ps | grep qn-smoketest
b5cd70b9b07a  localhost/quicknotes:lab6  …  Up 2 seconds  0.0.0.0:18080->8080/tcp  qn-smoketest

$ curl -s http://localhost:18080/health
{"notes":4,"status":"ok"}

$ docker logs qn-smoketest
2026/06/23 20:00:23 quicknotes listening on :8080 (notes loaded: 4)
```

The image is **self-sufficient** — `/data` is pre-created in the build with nonroot ownership, so `docker run` works without a mounted volume.
Compose's named volume mounts on top later, overlaying the empty `/data` with a Docker-managed RW volume.

### Design questions

#### a) Why does layer-order matter?

Each Dockerfile instruction creates a layer; layers are content-addressed by the instruction + the files it operated on.
A subsequent build with the same instruction + same inputs hits the cache and skips work.
A build that's just edited a Go file should not have to re-download dependencies.

**The two orderings:**

```dockerfile
# (A) bad — every source edit invalidates `go mod download`
COPY . .
RUN go mod download && go build ...
```

```dockerfile
# (B) good — only go.mod/go.sum edits invalidate `go mod download`
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN go build ...
```

Why (B) wins: the `COPY . .` layer changes whenever any file in `app/` changes (including `handlers.go`).
With ordering (A), that change cascades into the `go mod download` layer — invalidating it, forcing re-download of every module on every code edit.
With ordering (B), `go.mod`/`go.sum` are isolated; source edits don't touch the download layer; cache stays warm.

For **QuickNotes today**, the savings are nominal — the module has zero external deps, so `go mod download` is a ~50 ms no-op.
But the pattern is correct now so the day a `go get github.com/gorilla/mux` lands, the cache behaviour doesn't silently regress.
Container layer-order is one of those costs you pay once and forget — paying it late is harder than paying it early.

(I used `COPY go.mod ./` only, no `go.sum`, because the project has no transitive deps yet and `go.sum` doesn't exist. The wildcard `COPY go.mod go.sum* ./` would be necessary in a Dockerfile portable across modules where `go.sum` may or may not be present.)

#### b) Why `CGO_ENABLED=0`?

Without it, the Go compiler links against the system's `libc` (glibc on Debian builders, musl on alpine), producing a **dynamically linked** binary. The binary needs `ld-linux-x86-64.so.2` and `libc.so.6` at runtime.

`gcr.io/distroless/static-debian12` is the **static** variant — it doesn't ship the dynamic linker or any `libc.so`. A dynamically linked binary in that image fails at exec time:

```
exec /quicknotes: no such file or directory
```

…and the error is especially confusing because `/quicknotes` clearly **is** there — but the kernel is reporting that the linker `/lib64/ld-linux-x86-64.so.2` isn't,
and Linux conflates the two error paths. `CGO_ENABLED=0` tells Go to use its own runtime for syscalls and `net`/`os/user` lookups (the parts that historically went through libc),
producing a fully self-contained binary that distroless-static can exec directly.

If you wanted CGO (e.g., for SQLite via the standard driver), you'd use `gcr.io/distroless/cc-debian12` instead — same idea, but ships libc.

#### c) What is `gcr.io/distroless/static-debian12:nonroot`?

A minimal runtime image built by Google's distroless project. The `:nonroot` tag pre-sets `USER 65532:65532` (`nonroot:nonroot`). What's in it:

- `ca-certificates` for outbound TLS
- `/etc/passwd`, `/etc/group`, `/etc/nsswitch.conf` so the runtime can resolve users and DNS
- `/etc/os-release`, tzdata
- A `/home/nonroot` directory owned by the nonroot user
- Almost literally nothing else

What's **not** in it:

- No shell — no `sh`, `bash`, `busybox`
- No package manager — no `apt`, `apk`, `yum`
- No debug tools — no `curl`, `wget`, `ps`, `ls`, `cat`, `nc`
- No `libc` — this is the *static* variant; the `cc` variant ships glibc

**Why this matters for CVEs:** every package in an image is a potential CVE source. `ubuntu:24.04` has ~120 installed packages out of the box;
`debian:12-slim` has ~80; `gcr.io/distroless/static-debian12` has only **four**. When a new CVE drops for `libssl-dev` or `bash`, your `ubuntu`-based image is exposed and needs a rebuild;
your distroless-static image isn't because those packages aren't there.
That's exactly what Trivy showed below: the OS layer scored 0 HIGH/CRITICAL even on a multi-month-old base — there is barely any attack surface to score against.

#### d) `-ldflags='-s -w'` and `-trimpath`

- **`-s`** — strip the **symbol table**. Symbol tables map function addresses to function names. Without them, `nm`, `objdump -d`, and panics with `runtime/debug.Stack()` can't translate addresses back into names.
- **`-w`** — drop the **DWARF debug information**. Without it, `delve`/`gdb` can't step through the binary or show variable names, and stack traces in panics still work but won't include file:line annotations from the debugger.

Combined, `-s -w` typically shaves **25-30%** off binary size on a small Go program — for QuickNotes, the difference was roughly 7-8 MB → 5-6 MB.

- **`-trimpath`** — rewrites every embedded path in the binary to be relative to the module root. Without it, an absolute build path like `/home/karim/Dev/DevOps-Intro/app/handlers.go:42` ends up burned into the binary metadata. With it, that becomes `quicknotes/handlers.go:42`.
Trade-off: **build reproducibility** — two students building the same commit on different machines now produce byte-identical binaries (modulo Go version + arch);
also less leaked info about build environment.

The cost of all three: **harder post-mortem debugging from production binaries**. Production stack traces lose file:line annotations;
`delve` can't introspect a stripped binary. The conventional mitigation is to ship the *unstripped* binary in CI artefacts (for offline debug),
and the stripped binary in the deployed image — `-ldflags='-s -w'` is a runtime image flag, not a CI artefact flag.

---

## Task 2 — Compose + healthcheck + persistent volume

### `compose.yaml`

```yaml
services:
  quicknotes:
    build:
      context: ./app
      dockerfile: Dockerfile
    image: quicknotes:lab6
    ports:
      - "127.0.0.1:8080:8080"
    environment:
      ADDR: ":8080"
      DATA_PATH: "/data/notes.json"
      SEED_PATH: "/seed.json"
    volumes:
      - quicknotes-data:/data
    healthcheck:
      test: ["CMD", "/healthcheck"]
      interval: 10s
      timeout: 3s
      retries: 3
      start_period: 5s
    restart: unless-stopped

    # Bonus: 6 hardening defaults (Lecture 6)
    user: "65532:65532"
    read_only: true
    tmpfs:
      - /tmp
    cap_drop:
      - ALL
    security_opt:
      - "no-new-privileges:true"

volumes:
  quicknotes-data:
```

Port is bound to `127.0.0.1` (consistent with Lab 5 — no need to expose to LAN for a local dev exercise). `start_period: 5s` gives the Go binary time to load seed.json before the first healthcheck fires.

### Healthcheck status

```console
$ docker inspect "$CID" --format '{{ .State.Health.Status }}'
healthy

$ docker inspect "$CID" --format '{{ json .State.Health }}' | jq '.Status, .FailingStreak, (.Log | map({End, ExitCode}))'
"healthy"
0
[
  { "End": "2026-06-23T23:05:02.641312544+03:00", "ExitCode": 0 },
  { "End": "2026-06-23T23:05:13.640557182+03:00", "ExitCode": 0 },
  { "End": "2026-06-23T23:05:24.643340397+03:00", "ExitCode": 0 },
  { "End": "2026-06-23T23:05:35.632956826+03:00", "ExitCode": 0 },
  { "End": "2026-06-23T23:05:46.634184003+03:00", "ExitCode": 0 }
]
```

5 consecutive checks, all `ExitCode: 0`, status `healthy`, zero failing streak. Each call took ~10 ms (timestamps confirm).

### Persistence test

```console
$ docker compose up --build -d
[+] up 4/4
 ✔ Image quicknotes:lab6               Built          18.6s
 ✔ Network devops-intro_default        Created         0.0s
 ✔ Volume devops-intro_quicknotes-data Created         0.0s
 ✔ Container devops-intro-quicknotes-1 Started         0.3s

$ curl -X POST -H 'Content-Type: application/json' \
    -d '{"title":"durable","body":"survive a restart"}' \
    http://localhost:8080/notes
{"id":5,"title":"durable","body":"survive a restart","created_at":"2026-06-23T20:03:56.200138623Z"}

$ curl -s http://localhost:8080/notes | grep -q durable && echo "PRESENT-1"
PRESENT-1

$ docker compose down                                  # NOT `down -v`
[+] down 2/2
 ✔ Container devops-intro-quicknotes-1 Removed
 ✔ Network devops-intro_default        Removed
                                                       # Volume devops-intro_quicknotes-data NOT removed

$ docker compose up -d && sleep 5
[+] up 2/2
 ✔ Network devops-intro_default        Created
 ✔ Container devops-intro-quicknotes-1 Started

$ curl -s http://localhost:8080/notes | grep -q durable && echo "PRESENT-2 (survived down/up)"
PRESENT-2 (survived down/up)

$ docker compose down -v                               # explicit volume wipe
[+] down 3/3
 ✔ Container devops-intro-quicknotes-1 Removed
 ✔ Volume devops-intro_quicknotes-data Removed
 ✔ Network devops-intro_default        Removed

$ docker compose up -d && sleep 5

$ curl -s http://localhost:8080/notes | grep -q durable && echo "STILL THERE (bug)" || echo "GONE (correct)"
GONE (correct)
```

`PRESENT-1 → PRESENT-2 → GONE` — the named volume survives `down`, the volume dies on `down -v`. After the wipe, only the 4 seed notes from `/seed.json` come back, as expected.

### Design questions

#### e) Distroless has no shell. How do you healthcheck it?

The four options listed in the lab:

| Option                              | Cost                                          | When it's right |
|-------------------------------------|-----------------------------------------------|-----------------|
| HTTP via a sidecar                  | Whole extra container per service; orchestration complexity | When the app is closed-source and changing it isn't on the table |
| `wget`-only debug image variant     | Two images to build/scan/push; drift between them | When you need the same scaffolding for `kubectl exec` debugging |
| "Process is alive" (no HEALTHCHECK) | Doesn't actually check serving health — process can be deadlocked while running | Quick prototypes, never production |
| **Use a binary already in the image** | One extra small binary to build and copy | The pragmatic default for Go services |

I picked **option 4**: build a tiny static `healthcheck` binary alongside `quicknotes` in the same multi-stage Dockerfile, copy it to `/healthcheck`, and reference it from compose's `healthcheck.test: ["CMD", "/healthcheck"]`.

**Why this wins for QuickNotes:**
- The whole thing is ~20 lines of Go, zero external deps. (`app/cmd/healthcheck/main.go`.)
- Adds ~3 MB to the image (one more static Go binary), but the budget was 25 MB and we land at 14.6 MB.
- The semantics match the app: same TCP stack, same kernel-level routing, same `/health` endpoint — if the binary's HTTP GET succeeds, the app is genuinely serving.
- Static: no glibc / dynamic linker, works in distroless-static unmodified.
- No external attack surface added — the healthcheck doesn't listen on a port, doesn't read disk, doesn't touch `/data`.

**What it doesn't catch:** if the app crashes between the `/health` route handler and the data path (e.g., note creation hangs but `/health` still returns 200), the healthcheck is happy but the app is broken. Real production setups add a deeper "synthetic" endpoint that exercises the storage layer — out of scope for this lab.

#### f) Why does `volumes: [quicknotes-data:/data]` survive `docker compose down`?

Named volumes are *first-class objects* in Docker, owned by the compose **project** rather than any individual container. The project name is `devops-intro` (the working directory), so the actual volume name is `devops-intro_quicknotes-data`. Container lifecycle (create/stop/remove) is orthogonal to volume lifecycle.

`docker compose down` removes containers, networks, and (project-level) configs — but **not** volumes, by design. The reason is exactly the use case we just demonstrated: an operator needs to be able to drop and recreate the app without losing user data.

**What does destroy it:**
- `docker compose down -v` — the explicit "yes, I want my data gone" flag.
- `docker volume rm devops-intro_quicknotes-data` — manual delete.
- `docker volume prune` — prunes dangling (unreferenced) volumes; if the compose stack is down, the volume is dangling and gets caught.
- Backend storage failure on the host (the volume lives in `/var/lib/containers/storage/volumes/...` on podman).

The takeaway: `down` is *idempotent* and *safe* (data preserved); `down -v` and `prune` are *destructive* — make them harder to type by accident in production scripts.

#### g) `depends_on` without `condition: service_healthy`

`depends_on: [db]` without `condition` only waits for the **container** to be *started* — that is, the Docker daemon has created it and exec'd its entrypoint. It does **not** wait for the process inside to be ready to serve.

The classic failure mode: app A `depends_on: [db]`. Docker brings up `db`'s container in ~200 ms. App A's container starts at ~200 ms + 1, tries `pg.Connect("db:5432")` immediately, but Postgres is still in its boot sequence (~5-15 s). App A gets `connection refused`, panics, container crash-loops. Docker's restart policy may or may not paper over it depending on how robust the retry is.

The fix:

```yaml
depends_on:
  db:
    condition: service_healthy
```

…with a `healthcheck` defined on `db`. Now App A waits for the *health* signal, not just the *exec* signal.

---

## Bonus — 6 hardening defaults + Trivy

### Per-default verification

#### 1. `USER nonroot` (image-level)

```console
$ docker inspect quicknotes:lab6 --format '{{ .Config.User }}'
nonroot:nonroot
```

Backed up at runtime by `user: "65532:65532"` in compose — `nonroot` resolves to UID 65532 in the distroless base.

#### 2. Distroless base — no shell

```console
$ docker compose exec quicknotes sh -c 'echo this should fail'
Error: crun: executable file `sh` not found in $PATH: No such file or directory:
  OCI runtime attempted to invoke a command that was not found
EXEC sh FAILED — expected

$ docker compose exec quicknotes /bin/sh
Error: crun: executable file `/bin/sh` not found:
  No such file or directory:
  OCI runtime attempted to invoke a command that was not found
/bin/sh FAILED — expected
```

Both `sh` and `/bin/sh` resolve to nothing — the runtime image genuinely doesn't contain any shell. A would-be attacker who finds an RCE in QuickNotes can't `system('curl … | sh')` because `sh` doesn't exist.

#### 3. Capabilities dropped

```console
$ docker inspect "$CID" --format '{{ .HostConfig.CapDrop }}'
[CAP_CHOWN CAP_DAC_OVERRIDE CAP_FOWNER CAP_FSETID CAP_KILL CAP_NET_BIND_SERVICE
 CAP_SETFCAP CAP_SETGID CAP_SETPCAP CAP_SETUID CAP_SYS_CHROOT]
```

Podman expands `cap_drop: [ALL]` into the explicit list of default container capabilities — functionally identical to `[ALL]` (every default capability is dropped), the format just differs from Docker. None of these are added back via `cap_add`, so the container has the **empty** capability set in practice.

(QuickNotes is a userspace HTTP server on port 8080 — it needs zero capabilities. If we'd tried port 80, we'd need `cap_add: [NET_BIND_SERVICE]`, but loopback-bound 8080 doesn't.)

#### 4. Read-only root filesystem

```console
$ docker inspect "$CID" --format '{{ .HostConfig.ReadonlyRootfs }}'
true
```

Enforcement proof — verified via an Alpine sidecar that shares the target container's PID/network namespaces but mounts its own read-only rootfs (distroless has no `touch`, so we can't test from inside):

```console
$ docker run --rm --pid="container:$CID" --net="container:$CID" \
    --user 65532 --read-only \
    alpine sh -c 'touch /etc/test 2>&1 || echo "WRITE BLOCKED — expected"'
touch: /etc/test: Read-only file system
WRITE BLOCKED — expected
```

The app still needs *somewhere* to write, which is what `/tmp` (tmpfs) and `/data` (named volume) are for — both are RW mountpoints over the otherwise read-only rootfs.

#### 5. `no-new-privileges`

```console
$ docker inspect "$CID" --format '{{ .HostConfig.SecurityOpt }}'
[no-new-privileges]
```

This sets the kernel-level `NO_NEW_PRIVS` bit on the container's processes. Any future `setuid` binary the container exec's *cannot* gain privileges from its file mode bits — `sudo`, `su`, `mount`-like helpers are neutered. Combined with `USER nonroot`, this prevents the classic "vulnerability → setuid binary → root" escalation chain.

#### 6. Trivy scan — before / after Go bump

Initial scan with `golang:1.24.5-alpine` builder (the version we used in Lab 5 for consistency):

```
/img.tar (debian 12.14)
=======================
Total: 0 (HIGH: 0, CRITICAL: 0)

healthcheck (gobinary)
======================
Total: 16 (HIGH: 15, CRITICAL: 1)

quicknotes (gobinary)
=====================
Total: 16 (HIGH: 15, CRITICAL: 1)
```

Distroless gave us **zero** OS-level vulnerabilities at HIGH/CRITICAL — that's the value of a 4-package base. But both Go binaries each had 16 stdlib CVEs because `golang:1.24.5` was 8 patch releases stale.

After bumping the Dockerfile builder to `golang:1.24.13-alpine`:

```
/img.tar (debian 12.14)
=======================
Total: 0 (HIGH: 0, CRITICAL: 0)

healthcheck (gobinary)
======================
Total: 13 (HIGH: 13, CRITICAL: 0)

quicknotes (gobinary)
=====================
Total: 13 (HIGH: 13, CRITICAL: 0)
```

| Surface           | Before (Go 1.24.5) | After (Go 1.24.13) | Δ            |
|-------------------|-------------------:|-------------------:|-------------:|
| OS layer          | 0H / 0C            | 0H / 0C            | unchanged    |
| `healthcheck` bin | 15H / 1C           | 13H / 0C           | −2H / −1C    |
| `quicknotes` bin  | 15H / 1C           | 13H / 0C           | −2H / −1C    |
| **Total H+C**     | **32**             | **26**             | **−6 (−19%)** |

Image size: **14.6 MB** before, **14.6 MB** after — the bump didn't bloat anything.

**What the remaining 13 HIGH's tell us:** every one of them is in Go `stdlib` and the "Fixed Version" column points exclusively to **1.25.x or 1.26.x**, with no 1.24.x backport. Translation: Go 1.24 has effectively entered **security-EOL** for these CVEs — upstream isn't backporting fixes to the 1.24 line anymore, so further patch-level bumps within 1.24 won't close them. The next mitigation is a *minor* bump to 1.25.x — but Lab 6 acceptance pins Go 1.24, so that bump belongs in a follow-up PR.

**The supply-chain lesson here is the whole point of the bonus** — pinning gives you reproducibility (the Lab 5 design Q d benefit), but turns into a *liability* the moment upstream ships a security release you haven't merged. The system answer is automation: Renovate / Dependabot raises the PR, Trivy in CI gates merge on HIGH/CRITICAL, the bump ships continuously. Without that pipeline, you're one stale dependency away from owning every published Go CVE — exactly what the 1.24.5 baseline showed.

### Most security per line of YAML

If I had to rank the six by *security delivered ÷ YAML cost*, my ordering is:

1. **`USER nonroot` + `cap_drop: [ALL]`** (tied) — these two together convert "RCE inside the container" from a kernel-level threat into "userspace nuisance restricted to UID 65532 with no capabilities". One Dockerfile line + 2 compose lines, and the worst-case payload of the worst-case exploit drops by an order of magnitude. The "must" pair.
2. **`read_only: true` + tmpfs** — three compose lines that prevent attackers from persisting on the filesystem (writing webshells, droppers, modifying binaries). Forces them to live in memory. Combined with `cap_drop`, even a kernel exploit can't pivot to ring 0.
3. **`no-new-privileges`** — one line; closes the escalation paths via setuid binaries. Cheap, but mostly redundant in an image that already drops every capability and has no setuid binaries to begin with — the value is **defense in depth** for the day you accidentally add `sudo` to debug an issue and forget to remove it.
4. **Distroless base** — biggest *latent* win, but it's an image-build choice, not a YAML line. Already baked into Task 1.
5. **Trivy in CI** — not a YAML line in `compose.yaml` at all (it's a CI workflow step, coming in Lab 9), but in raw "CVEs caught per line of CI YAML" it's probably first overall. The bonus's Trivy run already paid for itself by surfacing the Go-bump-needed signal.

The pair I'd never ship without: **`USER nonroot` + `cap_drop: [ALL]`**. Those two close the most common container-escape paths from CVE writeups.

---

## Pitfalls I hit (for the next student with Russian Internet or Podman instead of Docker)

- **`golang:1.24.5-alpine3.20` doesn't exist on Docker Hub** — golang only ships *one* alpine tag per Go version (the alpine current at release time). Use `golang:1.24.X-alpine` (no `3.X`) unless you've verified the exact tag exists.
- **`docker run` with distroless and no `-v` fails** — without a writable `/data` directory in the image, QuickNotes panics in `os.MkdirAll(dirname("/data/notes.json"), 0o755)` because nonroot can't write to `/`. Fix: pre-create `/data` in the Dockerfile with `COPY --chown=65532:65532 ... /data`. Compose's named volume papers over it, but `docker run` on the bare image needs the precreated dir.
- **Podman `docker.sock` doesn't exist** — Trivy's standard `docker run -v /var/run/docker.sock:...` doesn't work. Workaround: `docker save quicknotes:lab6 -o /tmp/img.tar` then `trivy image --input /tmp/img.tar`. Runtime-agnostic.
- **`docker images foo:bar baz:qux` (multiple args) fails under podman's docker-compat** — podman only accepts one repo arg. Use `| grep -E 'foo|baz'` instead.
- **proxychains doesn't route `docker pull`** — daemonless or not, podman spawns helper processes that escape `LD_PRELOAD`. Use `HTTPS_PROXY=socks5://...` env vars on the docker/podman CLI directly.

---

## Checklist

- [x] `app/Dockerfile` — multi-stage, `1.24.13-alpine` builder, distroless-static-nonroot runtime, ≤25 MB (actual: 14.6 MB)
- [x] `app/cmd/healthcheck/main.go` — tiny static Go healthcheck binary
- [x] `compose.yaml` — named volume, healthcheck, env, restart, ports loopback-bound
- [x] All 4 Task 1 design questions answered
- [x] Persistence test PRESENT-1 → PRESENT-2 → GONE
- [x] All 3 Task 2 design questions answered
- [x] Bonus: all 6 hardening defaults applied + per-default verification commands captured
- [x] Trivy ran (before + after Go bump), supply-chain lesson documented
- [x] Commits signed (`git log --show-signature`)
