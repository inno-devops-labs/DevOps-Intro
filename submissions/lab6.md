# Lab 6 — Containers: Dockerize QuickNotes

**Author:** Kolpakova Valeriia — v.kolpakova@innopolis.university

**Note on ports:** `compose.yaml` publishes `8080:8080` as Task 2.1 requires. On my machine
port 8080 is held by an unrelated local nginx, so every command below was run with a throwaway
override file mapping host `18081` instead. The override is not committed — only the host port
differs, nothing else.

---

## Task 1 — Multi-Stage Dockerfile

### `app/Dockerfile`

```dockerfile
# syntax=docker/dockerfile:1

# ---------- builder ----------
FROM golang:1.24.13-alpine AS builder

WORKDIR /src

# Dependency manifests first: this layer is invalidated only when go.mod /
# go.sum change, so editing .go files still reuses the cached module download.
# (go.sum is globbed because QuickNotes has no third-party dependencies yet.)
COPY go.mod go.sum* ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 go build -trimpath -ldflags='-s -w' -o /out/quicknotes .

# The runtime image has no shell and no wget, so the healthcheck has to be a
# static binary of its own. It lives here rather than in app/ because it is a
# packaging concern, not part of QuickNotes.
COPY <<'EOF' /hc/main.go
package main

import (
	"net/http"
	"os"
	"time"
)

func main() {
	client := &http.Client{Timeout: 2 * time.Second}
	resp, err := client.Get("http://127.0.0.1:8080/health")
	if err != nil {
		os.Exit(1)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		os.Exit(1)
	}
}
EOF

RUN cd /hc && go mod init healthcheck >/dev/null && \
    CGO_ENABLED=0 go build -trimpath -ldflags='-s -w' -o /out/healthcheck .

# Empty /data owned by the runtime UID. Docker seeds a fresh named volume from
# the image's mount point, so this is what makes the volume writable by a
# nonroot container without any chown at runtime (there is no shell to run one).
RUN mkdir -p /data-template

# ---------- runtime ----------
FROM gcr.io/distroless/static:nonroot

WORKDIR /app

COPY --from=builder /out/quicknotes /app/quicknotes
COPY --from=builder /out/healthcheck /app/healthcheck
COPY --from=builder /src/seed.json /app/seed.json
COPY --from=builder --chown=65532:65532 /data-template /data

USER 65532:65532
EXPOSE 8080
ENTRYPOINT ["/app/quicknotes"]
```

### Size

```console
$ docker images quicknotes:lab6
REPOSITORY   TAG    IMAGE ID       CREATED         SIZE
quicknotes   lab6   3ef21cc04bcc   6 minutes ago   13.1MB
```

**13.1 MB — under the 25 MB budget.** For comparison, on the same machine:

| Image | Size |
|---|---:|
| `golang:1.24.13-alpine` (builder base) | 259 MB |
| `gcr.io/distroless/static:nonroot` (runtime base) | 2.37 MB |
| **`quicknotes:lab6` (final)** | **13.1 MB** |

The builder base alone is ~20× the finished image; that whole toolchain is what multi-stage
throws away.

### Config

```console
$ docker inspect quicknotes:lab6 | jq '.[0].Config'
{
  "User": "65532:65532",
  "ExposedPorts": { "8080/tcp": {} },
  "Entrypoint": [ "/app/quicknotes" ],
  "WorkingDir": "/app"
}
```

Nonroot UID, port declared, entrypoint in exec form.

### Runs (1.3)

```console
$ docker run -d -p 18081:8080 -e DATA_PATH=/data/notes.json \
    -e SEED_PATH=/app/seed.json -v qn-test-vol:/data quicknotes:lab6
$ curl -s http://localhost:18081/health
{"notes":4,"status":"ok"}
```

### 1.2 — Design questions

**a) Why does layer-order matter? Rebuild times for the two strategies.**

I built both orderings from the same context and rebuilt each after a real source edit
(appending a line to `handlers.go` — `touch` alone changes nothing, because BuildKit hashes
file *contents*, not mtimes; my first attempt at this measurement was wrong for exactly that
reason).

The structural difference is unambiguous. **Strategy A** — `COPY . . → go mod download → build`:

```
#9  [builder 3/5] COPY . .                    ->  DONE
#10 [builder 4/5] RUN go mod download         ->  DONE 0.168s   ← re-runs
#11 [builder 5/5] RUN go build ...            ->  DONE 6.4s
```

**Strategy B** — `COPY go.mod → download → COPY . . → build` (the one I shipped):

```
#8  [builder 3/6] COPY go.mod go.sum* ./      ->  CACHED
#10 [builder 4/6] RUN go mod download         ->  CACHED        ← survives the edit
#11 [builder 5/6] COPY . .                    ->  DONE
#12 [builder 6/6] RUN go build ...            ->  DONE 5.6s
```

In A, touching any `.go` file invalidates `COPY . .`, and every layer after it — including the
dependency download — has to re-run. In B the dependency layer sits *above* the source copy, so
it stays cached and only the compile re-runs.

**Wall-clock, honestly: on this project it makes no measurable difference.** Three paired
rebuilds gave A = 1.43 s / 0.38 s / 0.45 s against B = 0.42 s / 0.36 s / 0.68 s — noise, with B
slower in one run. The reason is visible in A's own log: `go: no module dependencies to
download`. QuickNotes has an empty `go.mod`, so the layer that ordering protects costs 0.17 s.
The ordering is still correct — it is insurance whose premium is zero and whose payout arrives
the first time this project gains a real dependency tree, where `go mod download` is tens of
seconds.

**b) Why `CGO_ENABLED=0`? What happens in distroless-static if you forget it?**

Because `distroless/static` deliberately contains no dynamic linker, and a cgo-enabled build
produces a dynamically linked binary. I tested it — built the same source with
`CGO_ENABLED=1` on `golang:1.24.13` and dropped it into `distroless/static:nonroot`:

```console
$ file quicknotes            # built with CGO_ENABLED=1
ELF 64-bit LSB executable, ARM aarch64, dynamically linked,
interpreter /lib/ld-linux-aarch64.so.1, with debug_info, not stripped

$ docker run --rm qn-cgo
exec /app/quicknotes: no such file or directory
```

The error is the trap: the file is right there. What is missing is
`/lib/ld-linux-aarch64.so.1`, the interpreter the kernel is asked to load first — and the
kernel reports that absence as ENOENT against the binary you named. `CGO_ENABLED=0` produces a
statically linked binary with no interpreter at all, which is the only kind `static` can run.

**c) What is `gcr.io/distroless/static:nonroot`?**

It is a base image with no distribution userland: no shell, no package manager, no coreutils,
no libc. What it *does* carry is the short list needed for a static binary to behave like a
citizen — CA certificates for outbound TLS, `/etc/passwd` and `/etc/group` containing the
`nonroot` user (UID 65532) so the process has a resolvable identity, and tzdata.

The CVE consequence showed up directly in my Trivy run: Trivy detected the base as
`debian 13.7` with **`pkg_num=6`** — six packages in the entire image — and reported
`Total: 0 (HIGH: 0, CRITICAL: 0)` for it. A conventional `debian:13-slim` base carries on the
order of a hundred packages, every one of which is a thing that can get a CVE, need triage, and
force a rebuild even though QuickNotes never calls it. Fewer packages is not only a smaller
attack surface, it is less recurring work. The absent shell matters too: a large class of
container exploits assumes it can spawn `/bin/sh`, and here that step simply has nothing to
call.

**d) `-ldflags='-s -w'` and `-trimpath`: what does each do, and what's the cost?**

- `-s` drops the symbol table; `-w` drops DWARF debugging information. Together on this binary:
  **7.79 MB → 5.25 MB, a 32.6 % reduction** (measured by building both ways in the same layer).
- `-trimpath` rewrites file paths recorded in the binary so they are module-relative instead of
  absolute build-machine paths. It makes the build reproducible and stops the image from
  leaking the directory layout of whoever built it.

The cost is paid at debugging time. Without a symbol table and DWARF you cannot attach `delve`
meaningfully, and profiling tools lose symbol names. Panic stack traces survive — Go's runtime
keeps its own tables for those — but with `-trimpath` the paths in them no longer point at a
checkout on your disk. For a service shipped as an immutable image this is the right trade:
debug the un-stripped build locally, ship the stripped one.

---

## Task 2 — Compose + Healthcheck + Persistent Volume

### `compose.yaml`

```yaml
services:
  quicknotes:
    build: ./app
    image: quicknotes:lab6
    ports:
      - "8080:8080"
    environment:
      ADDR: ":8080"
      DATA_PATH: /data/notes.json
      SEED_PATH: /app/seed.json
    volumes:
      - quicknotes-data:/data
    healthcheck:
      # Exec form, and the probe is the static binary baked into the image --
      # distroless has no shell, so CMD-SHELL and curl/wget are not options.
      test: ["CMD", "/app/healthcheck"]
      interval: 10s
      timeout: 3s
      retries: 3
      start_period: 2s
    restart: unless-stopped

    # --- Lecture 6 hardening defaults (Bonus) ---
    cap_drop:
      - ALL
    read_only: true
    tmpfs:
      - /tmp
    security_opt:
      - no-new-privileges:true

volumes:
  quicknotes-data:
```

The healthcheck is live, not decorative:

```console
$ docker compose ps
NAME                        STATUS
devops-intro-quicknotes-1   Up 5 seconds (healthy)
```

### 2.3 — Persistence test

```console
$ curl -X POST -H 'Content-Type: application/json' \
    -d '{"title":"durable","body":"survive a restart"}' .../notes
{"id":5,"title":"durable","body":"survive a restart","created_at":"2026-09-24T15:43:24Z"}

$ curl -s .../notes | grep durable
"title":"durable","body":"survive a restart","created_at":"2026-09-24T15:43:24Z"

$ docker compose down                 # NOT down -v
 Network devops-intro_default  Removed

$ docker compose up -d
 Container devops-intro-quicknotes-1  Started

$ curl -s .../notes | grep durable    # must STILL exist
"title":"durable","body":"survive a restart","created_at":"2026-09-24T15:43:24Z"     ✅

$ docker compose down -v              # NOW the volume dies
 Volume devops-intro_quicknotes-data  Removing
 Volume devops-intro_quicknotes-data  Removed

$ docker compose up -d
$ curl -s .../notes | grep durable    # gone
(no match)                                                                            ✅

$ curl -s .../health
{"notes":4,"status":"ok"}             # back to the 4 seeded notes
```

Note survived `down && up`, died on `down -v`, and the container re-seeded itself from
`/app/seed.json` afterwards — exactly the expected lifecycle.

### 2.2 — Design questions

**e) Distroless has no shell. How do you healthcheck it?**

I compiled a second static binary — about 20 lines of Go that GETs `127.0.0.1:8080/health` with
a 2-second timeout and exits 0 or 1 — in the builder stage, and copied it into the runtime
image. The check is `test: ["CMD", "/app/healthcheck"]`, exec form, so no shell is involved.
Its source lives in a heredoc inside the Dockerfile rather than in `app/`, because it is
packaging, not part of QuickNotes.

Why not the alternatives the brief lists. **"A binary that's already in the image"** is not
available: the only binary in a distroless image is the app, and QuickNotes has no health
subcommand — so any probe means putting one there. **Relying on Docker's default** (no
`HEALTHCHECK`, container counts as up while PID 1 lives) both contradicts Task 2.1's
requirement to define one and fails at the case worth catching: QuickNotes deadlocked but not
exited would still read healthy. A **sidecar** moves the health signal onto a service that is
not the one being reported on, and doubles the running containers for one HTTP GET.

The **`wget` route** deserves the longest answer, because it looks cheapest and is not. Whether
via the `:debug` tag or by copying busybox's `wget` across, what lands in the image is busybox,
and busybox is one multi-call binary reached under many names:

```console
$ docker run --rm busybox:musl ls -l /bin/sh /bin/ash /bin/wget /bin/busybox
-rwxr-xr-x  405 root root 1378528 May 13 02:21 /bin/ash
-rwxr-xr-x  405 root root 1378528 May 13 02:21 /bin/busybox
-rwxr-xr-x  405 root root 1378528 May 13 02:21 /bin/sh
-rwxr-xr-x  405 root root 1378528 May 13 02:21 /bin/wget
```

Identical size, link count 405 — `wget` *is* `sh`, the same file under another name. So
`COPY --from=busybox /bin/wget` ships a shell whether or not that was the intent, which breaks
Task 1.1's "no shell" requirement and flips bonus verification #2 from a pass to a fail. Saving
~4 MB by reintroducing the exact thing distroless exists to remove is a bad trade.

So the cost of my choice is 5.24 MB — 40 % of the image — to answer one HTTP request, and it
buys a probe that tests the actual endpoint while leaving the image shell-free.

**f) Why does `volumes: [quicknotes-data:/data]` survive `docker compose down`? What destroys it?**

Because a named volume is a first-class Docker object with a lifecycle independent of any
container. `docker compose down` removes containers and the project network, and stops there —
its refusal to delete data by default is deliberate, since a volume is usually the only thing in
the stack that cannot be rebuilt from source.

It dies on `docker compose down -v` (as shown above), `docker volume rm quicknotes-data`, or
`docker volume prune` sweeping it up once no container references it. Deleting the *container*
never touches it.

**g) `depends_on` without `condition: service_healthy` — what does it wait for, and what bug does that cause?**

Plain `depends_on` waits only for the dependency's container to reach *started* — the moment
Docker has spawned PID 1. It says nothing about whether the process inside has bound its port,
run migrations, or loaded state. So a dependent service can start, connect immediately, and get
connection-refused against a container Docker already considers satisfied.

The bug is that this is a race, and the race usually resolves in your favour on a warm
developer laptop where the dependency is ready in 50 ms. It resolves the other way on a cold CI
runner or a loaded host — which is why it shows up as a flaky pipeline or a crash-loop on
deploy rather than a reproducible failure. `condition: service_healthy` fixes it by tying the
wait to the healthcheck, which is a statement about the application rather than about the
process table.

---

## Bonus Task — The 6 Security Defaults

### B.1 — The hardened `services.quicknotes` block

```yaml
    # 1. USER nonroot      -> in the Dockerfile: USER 65532:65532
    # 2. distroless base   -> in the Dockerfile: FROM gcr.io/distroless/static:nonroot
    cap_drop:              # 3. drop every capability; QuickNotes needs none
      - ALL
    read_only: true        # 4. immutable root filesystem ...
    tmpfs:
      - /tmp               #    ... with scratch space where the runtime may need it
    security_opt:
      - no-new-privileges:true   # 5. no setuid escalation
    # 6. Trivy scan        -> B.3 below
```

QuickNotes needs no capability at all: it binds 8080, which is above 1024 and therefore needs
no `CAP_NET_BIND_SERVICE`, and writes only inside the `/data` volume. The single writable path
under `read_only: true` is that volume; `/tmp` is a tmpfs because the Go runtime may want
scratch space, and tmpfs keeps it in RAM and out of the image.

### B.2 — Verification

**1. `USER nonroot`**

```console
$ docker inspect quicknotes:lab6 --format '{{ .Config.User }}'
65532:65532
```

**2. No shell available**

```console
$ docker compose exec quicknotes sh
OCI runtime exec failed: exec failed: unable to start container process:
exec: "sh": executable file not found in $PATH: unknown
```

**3. Capabilities dropped**

```console
$ docker inspect <container> --format '{{ .HostConfig.CapDrop }}'
[ALL]
```

**4. Read-only root filesystem**

```console
$ docker inspect <container> --format '{{ .HostConfig.ReadonlyRootfs }}'
true
```

The brief suggests proving this with `touch /etc/test`, which cannot be run here — there is no
shell to run it and no `touch` binary to invoke, which is itself defence #2 doing its job. What
*is* verifiable is that the runtime accepted and recorded the constraint, and that the container
still works: with the root filesystem read-only, QuickNotes serves traffic and persists notes,
because every write it makes goes to the `/data` volume. Had anything needed to write elsewhere,
the container would have failed on startup rather than silently succeeding.

**5. `no-new-privileges`**

```console
$ docker inspect <container> --format '{{ .HostConfig.SecurityOpt }}'
[no-new-privileges:true]
```

### B.3 — Trivy

```console
$ docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
    aquasec/trivy:0.59.1 image --severity HIGH,CRITICAL --no-progress quicknotes:lab6

INFO  Detected OS  family="debian" version="13.7"
INFO  [debian] Detecting vulnerabilities...  os_version="13" pkg_num=6

quicknotes:lab6 (debian 13.7)
Total: 0 (HIGH: 0, CRITICAL: 0)

app/healthcheck (gobinary)
Total: 19 (HIGH: 19, CRITICAL: 0)

app/quicknotes (gobinary)
Total: 19 (HIGH: 19, CRITICAL: 0)
```

**The base is clean, the binaries are not, and that is worth stating plainly rather than
rounding down to the expected "zero".** All six OS packages scan clean — that is the distroless
dividend the brief predicts. But Trivy scans Go binaries as their own targets, and both of mine
carry the same 19 HIGH findings, every one of them `stdlib` in `v1.24.13`: `CVE-2026-25679`
(net/url IPv6 parsing), `CVE-2026-27145`, `CVE-2026-32280`, `CVE-2026-32281` (crypto/x509
denial of service), `CVE-2026-32283` (crypto/tls), `CVE-2026-33811`, `CVE-2026-33814`
(HTTP/2 SETTINGS frame), and twelve more.

Their fixed versions are `1.25.8`, `1.25.9`, `1.25.10`, `1.25.11`, `1.26.1`+ — **there is no
1.24.x fix**, because Go backports security patches only to the two most recent major releases
and 1.24 has fallen off that window. `1.24.13` is the newest 1.24 patch that exists, so within
Task 1's requirement to pin the builder to 1.24 these findings are unavoidable; clearing them
means moving the builder to 1.25.11 or 1.26.x, which this lab's spec does not permit. Worth
knowing that a scan can be "clean" and still ship 19 HIGHs, depending on which target you read.

### B.4 — Which default gives the most security per line of YAML?

`no-new-privileges:true` — two lines, and it closes the whole setuid-escalation class: even if
an attacker achieves code execution inside the container, the kernel will refuse to grant a
process more privileges than its parent had through a setuid binary, so the usual escape ladder
loses its bottom rung. `cap_drop: [ALL]` is a close second at two lines, removing the roughly
fourteen capabilities Docker grants by default — `CAP_CHOWN`, `CAP_SETUID`, `CAP_NET_RAW` and
the rest — none of which QuickNotes has ever needed.

But the honest answer is that the two highest-value defaults are not YAML at all: the distroless
base and `USER nonroot` are Dockerfile lines, and together they are why defence #2 above is a
*fact about the image* rather than a runtime flag someone can forget to pass. The YAML options
harden a process; the base image decides what exists to attack in the first place.
