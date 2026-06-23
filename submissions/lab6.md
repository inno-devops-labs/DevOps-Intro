# Lab 6 — Containers: Dockerize QuickNotes

> **Environment:** My lovely MacBook Air M4 as host.
>  Docker builds a native `linux/arm64` image; the distroless static base and the ≤ 25 MB target hold on arm64 just as on amd64 — only the CPU arch differs. 
---

What I have done ?

## Task 1 — Multi-Stage Dockerfile, ≤ 25 MB

### Dockerfile

`app/Dockerfile` (full source):

```dockerfile
FROM golang:1.24.13-bookworm AS builder

WORKDIR /src

COPY go.mod ./
RUN go mod download

# Now the source. This is the layer that changes when you edit code.
COPY . .

ENV CGO_ENABLED=0 GOOS=linux
RUN go build -trimpath -ldflags='-s -w' -o /out/quicknotes .

RUN go build -trimpath -ldflags='-s -w' -o /out/healthcheck ./healthcheck

RUN mkdir -p /data && touch /data/.keep && chown -R 65532:65532 /data


FROM gcr.io/distroless/static:nonroot AS runtime

WORKDIR /

COPY --from=builder /out/quicknotes  /quicknotes
COPY --from=builder /out/healthcheck /healthcheck
COPY --from=builder /src/seed.json   /seed.json
COPY --from=builder --chown=65532:65532 /data /data

ENV ADDR=":8080" \
    DATA_PATH="/data/notes.json" \
    SEED_PATH="/seed.json"

USER 65532:65532

EXPOSE 8080

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
  CMD ["/healthcheck"]

ENTRYPOINT ["/quicknotes"]
```

### `docker images` — final image size

```
$ docker images quicknotes:lab6
IMAGE             ID             DISK USAGE   CONTENT SIZE   EXTRA
quicknotes:lab6   1e12656f9f4c       21.7MB         5.32MB 
```

### `docker inspect` — User / ExposedPorts / Entrypoint

```
$ docker inspect quicknotes:lab6 | jq '.[0].Config | {User, ExposedPorts, Entrypoint}'

{
  "User": "65532:65532",
  "ExposedPorts": {
    "8080/tcp": {}
  },
  "Entrypoint": [
    "/quicknotes"
  ]
}

```

### Base-image size comparison

```text
$ docker images golang:1.24.13-bookworm 
IMAGE                     ID             DISK USAGE   CONTENT SIZE   EXTRA
golang:1.24.13-bookworm   1a6d4452c65d       1.26GB          309MB   
```

### Design questions

**a) Why layer-order matters (before/after rebuild times).**

Docker caches each instruction as a layer and reuses a layer only if it and
everything above it are unchanged. If you write
`COPY . . && go mod download && go build`, then **any** source edit changes the
`COPY . .` layer and invalidates the cache for `go mod download` too, so
dependencies are re-fetched on every rebuild. If you instead
`COPY go.mod[/go.sum] ./ && go mod download && COPY . . && go build`, the
dependency layer sits *above* the source copy, so editing a `.go` file only
re-runs from `COPY . .` and the cached module layer is reused.

QuickNotes has zero third-party dependencies, the wall-clock difference here is small — but the cache behavior is
identical, and on a real project with a big dependency tree this ordering turns
a multi-minute rebuild into seconds.

Because QuickNotes has **no** third-party dependencies, `go mod download` is a
no-op, so both orderings rebuild in essentially the same wall-clock time on my
machine — a few seconds, dominated by `go build`, not by dependency fetching.
The cache win here is therefore **structural, not measurable**: it only becomes
a real time saving once the project gains a dependency tree, where the bad order
re-downloads everything on every source edit.

**b) Why `CGO_ENABLED=0`; what happens in distroless-static if you forget.**

`CGO_ENABLED=0` forces a pure-Go, statically linked binary with no
dependency on a system C library. The distroless-static
base has no glibc/musl and no `ld.so`, so a cgo-enabled 
binary can't even start — it fails with `no such file or directory` (the kernel
can't find the missing interpreter) or missing `.so` errors. With CGO off the
binary is self-contained and runs on the empty base. 

**c) What is `gcr.io/distroless/static:nonroot`.**

Google's minimal runtime base. It contains essentially only: CA certificates,
`/etc/passwd`+`/etc/group`, tzdata,
and a home dir. It has no shell, no package manager, etc.

That matters for CVEs because the large majority of image vulnerabilities come
from OS packages (bash, apt, openssl, etc.) — none of which are present.

So there is almost nothing to scan, patch, or exploit, and no shell for an
attacker to pivot with. 

**d) `-ldflags='-s -w'` and `-trimpath`.**

`-s` strips the symbol table.  `-w` strips DWARF debug info — together they
shrink the binary noticeably. `-trimpath` removes absolute local build paths
from the binary, giving
**reproducible builds** (same source -> same bytes on any machine) and not
leaking my home directory layout. 

Cost: with `-s -w` you lose symbol/line
detail, so a debugger and symbol-based profiling won't work on the
stripped binary. `-trimpath` has no runtime cost,
it just means stack traces show trimmed module paths instead of local paths.

---

## Task 2 — Compose + Healthcheck + Persistent Volume

What I have done?

I created the `compose.yaml` — full source below.

### compose.yaml

`compose.yaml` (full source):

```yaml
name: quicknotes

services:
  quicknotes:
    build:
      context: ./app
      dockerfile: Dockerfile
    image: quicknotes:lab6
    container_name: quicknotes

    ports:
      - "8080:8080"

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

    # --- 6 security defaults ---
    read_only: true
    cap_drop:
      - ALL
    security_opt:
      - no-new-privileges:true
    tmpfs:
      - /tmp

volumes:
  quicknotes-data:
```

### Persistence test (note present → down → up → present → down -v → up → absent)

Here I put the whole persistence test: command + output

```
ephy@Starless-night app % docker compose up --build -d
[+] Building 5.0s (23/23) FINISHED  
[+] up 4/4
 ✔ Image quicknotes:lab6             Built                                                                                                                                                                 6.1s
 ✔ Network quicknotes_default        Created                                                                                                                                                               0.0s
 ✔ Volume quicknotes_quicknotes-data Created                                                                                                                                                               0.0s
 ✔ Container quicknotes              Started  

 ephy@Starless-night app % curl -X POST -H 'Content-Type: application/json' \
  -d '{"title":"durable","body":"survive a restart"}' \
  http://localhost:8080/notes
{"id":5,"title":"durable","body":"survive a restart","created_at":"2026-06-17T06:46:55.773586676Z"}


ephy@Starless-night app % curl -s http://localhost:8080/notes | grep durable
[{"id":1,"title":"Welcome to QuickNotes","body":"This is the project you'll containerize, deploy, monitor, and harden across all 10 labs.","created_at":"2026-01-15T10:00:00Z"},{"id":2,"title":"Read app/main.go first","body":"Start by understanding the entry point — env vars, signal handling, graceful shutdown.","created_at":"2026-01-15T10:05:00Z"},{"id":3,"title":"DevOps mantra","body":"If it hurts, do it more often.","created_at":"2026-01-15T10:10:00Z"},{"id":4,"title":"Endpoint cheat-sheet","body":"GET /notes  GET /notes/{id}  POST /notes  DELETE /notes/{id}  GET /health  GET /metrics","created_at":"2026-01-15T10:15:00Z"},{"id":5,"title":"durable","body":"survive a restart","created_at":"2026-06-17T06:46:55.773586676Z"}]

ephy@Starless-night app % docker compose down 
[+] down 2/2
 ✔ Container quicknotes Removed                                                                                                                                                                      0.2s
 ✔ Network quicknotes_default Removed 


 ephy@Starless-night app % docker compose up -d
[+] up 2/2
 ✔ Network quicknotes_default Created                                                                                                                                                                      0.0s
 ✔ Container quicknotes       Started  

ephy@Starless-night app % curl -s http://localhost:8080/notes | grep durable
[{"id":1,"title":"Welcome to QuickNotes","body":"This is the project you'll containerize, deploy, monitor, and harden across all 10 labs.","created_at":"2026-01-15T10:00:00Z"},{"id":2,"title":"Read app/main.go first","body":"Start by understanding the entry point — env vars, signal handling, graceful shutdown.","created_at":"2026-01-15T10:05:00Z"},{"id":3,"title":"DevOps mantra","body":"If it hurts, do it more often.","created_at":"2026-01-15T10:10:00Z"},{"id":4,"title":"Endpoint cheat-sheet","body":"GET /notes  GET /notes/{id}  POST /notes  DELETE /notes/{id}  GET /health  GET /metrics","created_at":"2026-01-15T10:15:00Z"},{"id":5,"title":"durable","body":"survive a restart","created_at":"2026-06-17T06:46:55.773586676Z"}]

ephy@Starless-night app % docker compose down -v  
[+] down 3/3
 ✔ Container quicknotes              Removed                                                                                                                                                               0.2s
 ✔ Network quicknotes_default        Removed                                                                                                                                                               0.2s
 ✔ Volume quicknotes_quicknotes-data Removed         

 ephy@Starless-night app % docker compose up -d
[+] up 3/3
 ✔ Network quicknotes_default        Created                                                                                                                                                               0.0s
 ✔ Volume quicknotes_quicknotes-data Created                                                                                                                                                               0.0s
 ✔ Container quicknotes              Started 

ephy@Starless-night app % curl -s http://localhost:8080/notes | grep durable
nothing here
```

### Design questions

**e) Distroless has no shell — how do you healthcheck it?**

I insert a tiny static Go script health-probe (`/healthcheck`) into the image and
the Compose healthcheck calls it: `test: ["CMD", "/healthcheck"]`. It does an
HTTP GET on the app's own `/health` and exits 0 (healthy) or 1 (unhealthy). 

I chose this over the alternatives, because, for example, a `wget`/`:debug` image puts a shell and busybox back into the
runtime and inflates the CVE surface. Docker's default "is the PID alive" only proves the process exists, not that the
HTTP server actually answers.



**f) Why does `quicknotes-data:/data` survive `docker compose down`?**

Because it's a named volume — a Docker-managed object with its own
lifecycle, independent of any container. `docker compose down` deletes the
containers and the network but leaves named volumes, so the next
`up` re-attaches the same volume with `notes.json` still inside. 
To destroy it: `docker compose down -v` (-v for  `--volumes` ), or `docker volume rm quicknotes-data`, or `docker volume prune`.

**g) `depends_on` without `condition: service_healthy`.**

Plain `depends_on` only waits for the dependency container to be started
 — not ready. So a dependent service can launch and immediately fail because the dependency's process is still booting. Adding `condition: service_healthy` makes Compose wait
until the dependency's healthcheck reports healthy first, removing the race.

---

## Bonus Task 

What I have done?

### Hardened `services.quicknotes` block

```yaml
  quicknotes:
    build:
      context: ./app
      dockerfile: Dockerfile
    image: quicknotes:lab6
    container_name: quicknotes
    ports:
      - "8080:8080"
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


    read_only: true                  #  read-only root filesystem
    cap_drop:
      - ALL                          # drop every Linux capability
    security_opt:
      - no-new-privileges:true       #  block setuid privilege escalation
    tmpfs:
      - /tmp                         # writable scratch under read_only
```


### Verification (each constraint is actually enforced)

```text
# 1+2  runs as nonroot
$ docker inspect quicknotes:lab6 --format '{{ .Config.User }}'
65532:65532

# no shell in the image (this SHOULD fail)
$ docker compose exec quicknotes sh
OCI runtime exec failed: exec failed: unable to start container process: exec: "sh": executable file not found in $PATH

# 3  capabilities dropped
$ docker inspect quicknotes --format '{{ .HostConfig.CapDrop }}'
[ALL]

# 4  read-only root filesystem
$ docker inspect quicknotes --format '{{ .HostConfig.ReadonlyRootfs }}'
true

# 5  no-new-privileges
$ docker inspect quicknotes --format '{{ .HostConfig.SecurityOpt }}'
[no-new-privileges:true]

```

### Trivy check

```text
$ trivy image --severity HIGH,CRITICAL --no-progress quicknotes:lab6
Report Summary

┌───────────────────────────────┬──────────┬─────────────────┬─────────┐
│            Target             │   Type   │ Vulnerabilities │ Secrets │
├───────────────────────────────┼──────────┼─────────────────┼─────────┤
│ quicknotes:lab6 (debian 13.5) │  debian  │        0        │    -    │
├───────────────────────────────┼──────────┼─────────────────┼─────────┤
│ healthcheck                   │ gobinary │       12        │    -    │
├───────────────────────────────┼──────────┼─────────────────┼─────────┤
│ quicknotes                    │ gobinary │       12        │    -    │
└───────────────────────────────┴──────────┴─────────────────┴─────────┘
```

**Reading the result.** The distroless base reports **0** vulnerabilities — the
payoff of a minimal base (no OS packages to be vulnerable). The 12 HIGH per
binary are all in the **Go standard library** (`stdlib v1.24.13`) compiled into
`quicknotes` and `healthcheck`. They show up
because the lab pins **Go 1.24**, which reached end-of-life in Feb 2026. 

**Which default gives the most security per line of YAML?**
The biggest single win is the **distroless + nonroot base**: it deletes the entire shell/package-manager  and stops the container running as root — two whole vulnerability classes removed by
one base-image line. 

Of the lines that live purely in `compose.yaml`,
**`cap_drop: ALL`** and **`no-new-privileges:true`** gives the most value: each is
single line that neutralizes an entire privilege-escalation class (kernel
capabilities).

`read_only: true` is the
next-best, blocking an attacker from persisting anything in the image at all.


