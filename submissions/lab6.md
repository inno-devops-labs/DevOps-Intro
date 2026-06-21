# Lab 6 — Containers

`app/Dockerfile` is a multi-stage build that produces a 21.6 MB distroless image running
as nonroot. `compose.yaml` (repo root) runs it with a healthcheck, a named volume, env vars,
a restart policy, and the six hardening defaults. Everything below is from real runs on this
machine (Docker 29.4.3, arm64).

## Task 1 — Multi-stage Dockerfile

### Dockerfile

```dockerfile
# ---------- build stage ----------
FROM golang:1.24 AS build
WORKDIR /src
COPY go.mod ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags='-s -w' -o /out/quicknotes .
# tiny static healthcheck binary (distroless has no shell/curl)
COPY <<'EOF' /src/hc/main.go
package main
import ("net/http"; "os")
func main() {
	resp, err := http.Get("http://127.0.0.1:8080/health")
	if err != nil || resp.StatusCode != http.StatusOK { os.Exit(1) }
}
EOF
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags='-s -w' -o /out/healthcheck ./hc
RUN mkdir -p /data && chown 65532:65532 /data

# ---------- runtime stage ----------
FROM gcr.io/distroless/static:nonroot
COPY --from=build /out/quicknotes /quicknotes
COPY --from=build /out/healthcheck /healthcheck
COPY --from=build /src/seed.json /seed.json
COPY --from=build --chown=65532:65532 /data /data
ENV ADDR=:8080 DATA_PATH=/data/notes.json SEED_PATH=/seed.json
USER 65532:65532
EXPOSE 8080
HEALTHCHECK --interval=10s --timeout=3s --start-period=3s --retries=3 CMD ["/healthcheck"]
ENTRYPOINT ["/quicknotes"]
```

### Image size and config

```text
$ docker images quicknotes:lab6
quicknotes:lab6   21.6MB                       # <= 25 MB requirement met

$ docker inspect quicknotes:lab6 --format '...'
User         = 65532:65532
ExposedPorts = {"8080/tcp":{}}
Entrypoint   = ["/quicknotes"]
```

Size comparison — the whole point of multi-stage:

| Image | Size |
|-------|-----:|
| `golang:1.24` (builder base, thrown away) | 1.33 GB |
| `gcr.io/distroless/static:nonroot` (runtime base) | 6.37 MB |
| **`quicknotes:lab6` (final)** | **21.6 MB** |

The 1.33 GB toolchain never reaches the final image; what ships is the distroless base plus two
small static Go binaries (the app + the healthcheck) and `seed.json`.

### Runs and serves

```text
$ docker run -d -p 8080:8080 quicknotes:lab6
$ curl -s http://localhost:8080/health
{"notes":4,"status":"ok"}
$ curl -s -X POST -d '{"title":"in container","body":"hi"}' http://localhost:8080/notes
{"id":5,"title":"in container","body":"hi","created_at":"2026-06-21T07:41:47Z"}
$ docker inspect <id> --format '{{.State.Health.Status}}'
healthy
```

### Design questions

**a) Why does layer order matter? (before/after rebuild times)**
The idea is to copy `go.mod`/`go.sum` and run `go mod download` *before* copying the source, so a
code change doesn't invalidate the (expensive) dependency-download layer. Measured on my Dockerfile:

```text
cold rebuild (--no-cache):                    6.16s
warm rebuild (source change, deps cached):    1.09s
no-op rebuild (all cached):                   0.95s
```

Honest caveat: QuickNotes has **no third-party dependencies** (std-lib only, no `go.sum`), so
`go mod download` is a no-op here and the `go.mod`-first trick saves ~0 on its own. The 6.16s→1.09s
win above is cache reuse of the base image and build layers. I still keep the ordering because it's
the correct shape — the moment the app gains one real dependency, a source-only change will skip
re-downloading modules instead of re-fetching them every build.

**b) Why `CGO_ENABLED=0`?**
It forces a fully static binary with no libc / dynamic-linker dependency. `distroless/static` has
no dynamic linker, so a default CGO build (dynamically linked to glibc) would fail at startup with
`no such file or directory` — which is really "the loader/libc the binary needs isn't there."
Static means the binary carries everything it needs.

**c) What is `gcr.io/distroless/static:nonroot`?**
A minimal runtime base with basically only CA certificates, timezone data, an `/etc/passwd` with a
`nonroot` user (UID 65532), and the few files a static binary expects — **no shell, no package
manager, no busybox, no libc**. That matters for CVEs because there are almost no OS packages to be
vulnerable: Trivy reports **0 HIGH/CRITICAL** on the base. Less stuff = smaller attack surface and
nothing for an attacker to pivot with (no shell).

**d) `-ldflags='-s -w'` and `-trimpath`?**
`-s` drops the symbol table and `-w` drops DWARF debug info — a smaller binary. `-trimpath` removes
absolute local paths from the binary, so the build is reproducible and doesn't leak my directory
layout. The cost is debuggability: with `-s -w` you lose symbols/debug info, so stack traces and
debuggers are less helpful — a fair trade for a production image.

## Task 2 — Compose + healthcheck + persistent volume

### compose.yaml

```yaml
name: quicknotes
services:
  quicknotes:
    build: ./app
    image: quicknotes:lab6
    ports: ["8080:8080"]
    environment:
      ADDR: ":8080"
      DATA_PATH: /data/notes.json
      SEED_PATH: /seed.json
    volumes:
      - quicknotes-data:/data
    healthcheck:
      test: ["CMD", "/healthcheck"]
      interval: 10s
      timeout: 3s
      retries: 3
      start_period: 3s
    restart: unless-stopped
    # hardening (bonus)
    read_only: true
    tmpfs: ["/tmp"]
    cap_drop: ["ALL"]
    security_opt: ["no-new-privileges:true"]
volumes:
  quicknotes-data:
```

### Persistence test

```text
$ docker compose up --build -d
$ curl -X POST -d '{"title":"durable","body":"survive a restart"}' .../notes
{"id":5,"title":"durable",...}
present before down?        -> durable

$ docker compose down          # NOT -v
$ docker compose up -d
present after down + up?      -> durable          # still there ✅

$ docker compose down -v       # removes the volume
$ docker compose up -d
present after down -v + up?    -> ''               # gone ✅
```

The note survived a `down`/`up` and only disappeared after `down -v`.

### Design questions

**e) Distroless has no shell — how do you healthcheck it?**
A shell-form `HEALTHCHECK` (or `test: curl ...`) can't run because there's no `/bin/sh`, `curl`, or
`wget`. I baked a tiny static Go binary (`/healthcheck`) into the image that does a GET on
`/health` and exits 0/1, and the check calls it in exec form: `["CMD", "/healthcheck"]`. I picked
this over the alternatives because a sidecar adds a whole extra container, and a debug image with
`wget` would put a shell/tooling back into the image and undo the point of going distroless.

**f) Why does the named volume survive `docker compose down`?**
`down` removes the containers and the network, but named volumes are separate objects with their
own lifecycle — they're not deleted unless you ask. The data lives in `quicknotes-data`, not in the
container, so a new container re-attaches to the same volume and sees the old notes. What *does*
destroy it: `docker compose down -v` (or `docker volume rm quicknotes_quicknotes-data`).

**g) `depends_on` without `condition: service_healthy`?**
Plain `depends_on` only waits for the dependency container to **start**, not to be **ready**. So if
QuickNotes depended on, say, a database, it could start while the DB is still booting and isn't
accepting connections yet — you get intermittent connection-refused errors at startup. The fix is
`depends_on: { dep: { condition: service_healthy } }`, which waits for the dependency's healthcheck
to pass.

## Bonus — the 6 hardening defaults

All six are applied (1–2 in the Dockerfile, 3–5 in compose, 6 via Trivy). Each verified:

```text
1) USER nonroot
   $ docker inspect quicknotes:lab6 --format '{{.Config.User}}'
   65532:65532

2) no shell in the image (distroless)
   $ docker compose exec quicknotes sh
   OCI runtime exec failed: exec: "sh": executable file not found in $PATH

3) all capabilities dropped
   $ docker inspect <c> --format '{{.HostConfig.CapDrop}}'
   [ALL]

4) read-only root filesystem
   $ docker inspect <c> --format '{{.HostConfig.ReadonlyRootfs}}'
   true
   (no shell to run `touch /etc/test`; the flag is the enforced proof. Only /data and the
    /tmp tmpfs are writable.)

5) no-new-privileges
   $ docker inspect <c> --format '{{.HostConfig.SecurityOpt}}'
   [no-new-privileges:true]
```

(Default 2, distroless base, and default 1, nonroot, both come from the Dockerfile.)

### Trivy (default 6)

```text
$ docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
    aquasec/trivy:0.59.1 image --severity HIGH,CRITICAL --no-progress quicknotes:lab6

quicknotes:lab6 (debian 13.5)         Total: 0  (HIGH: 0, CRITICAL: 0)
quicknotes (gobinary)                 Total: 12 (HIGH: 12, CRITICAL: 0)
healthcheck (gobinary)                Total: 12 (HIGH: 12, CRITICAL: 0)
```

Honest result: the **base image is clean** (0 HIGH/CRITICAL) — that's the value of distroless. But
the **Go binaries carry 12 HIGH stdlib CVEs** (e.g. `net/url`, `net/http`, `net/mail`) because they
were built with `go v1.24.13`; the fixes are in `1.25.8` / `1.26.1`. So a minimal base removes the
*OS* CVEs, but the Go standard library is compiled into the static binary — you still have to keep
the toolchain patched and rebuild. The fix here is to bump the builder image to a newer Go patch.

### Which default gives the most security per line of YAML?

`read_only: true` — one line makes the entire root filesystem immutable, which kills a whole class
of attacks at once: an attacker can't drop a binary, edit a config, or persist anything outside the
explicit `/data` volume and `/tmp` tmpfs. `cap_drop: ["ALL"]` is a close second (one line removes
every Linux capability), and `no-new-privileges` is the cheap insurance against setuid escalation.
Together they're four short lines that turn a normal container into a locked-down one.
