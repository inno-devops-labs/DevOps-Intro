# Lab 6 — Containerizing QuickNotes

Student: Arina ([@sonder314](https://github.com/sonder314))

## Task 1 — Multi-stage image

Implementation: [Dockerfile](../app/Dockerfile),
[build context exclusions](../app/.dockerignore), and
[healthcheck source](../app/cmd/healthcheck/main.go).
The official `golang:1.24-alpine` builder compiles and tests the application.
The runtime uses `gcr.io/distroless/static-debian12:nonroot`, contains the seed
file and an owned `/data` directory, and runs as `nonroot:nonroot` (UID/GID 65532).
Both Go binaries use `CGO_ENABLED=0`, `-trimpath`, and `-ldflags='-s -w'`.

The host used Docker 29.1.3 and Compose 2.40.3, rather than the prerequisite's
Docker 28.x. The recorded commands completed with these installed versions.

```text
$ docker images quicknotes:lab6
IMAGE             ID             DISK USAGE   CONTENT SIZE
quicknotes:lab6   a7427fdde67a       22.6MB         5.62MB

$ docker images golang:1.24-alpine
golang:1.24-alpine   8bee1901f1e5        395MB         83.5MB
```

The final image is below 25 MB even using Docker's larger disk-usage number.
Full evidence: [image size](evidence/lab6/image-size.txt),
[builder size](evidence/lab6/builder-image-size.txt),
[build output](evidence/lab6/image-build.txt), and
[static, stripped ELF verification](evidence/lab6/static-binary.txt).

The [image configuration](evidence/lab6/image-config.txt) contains:

```json
{"User":"nonroot:nonroot","ExposedPorts":{"8080/tcp":{}},"Entrypoint":["/quicknotes"]}
```

I also tested `docker run` independently of Compose, with `ADDR=0.0.0.0:8080`,
`DATA_PATH=/data/notes.json`, `SEED_PATH=/app/seed.json`, a named volume mounted
at `/data`, and host port 18081 forwarded to guest port 8080. The
[health request](evidence/lab6/direct-health.txt) returned
`{"notes":4,"status":"ok"}` and [GET /notes](evidence/lab6/direct-notes.txt)
returned all four seed notes.

### a) Why layer order matters

Changing a copied source file invalidates that layer and subsequent steps.
Copying the module manifest first preserves the dependency-download layer when
only application code changes. This project uses only the standard library,
so there is no `go.sum` and `go mod download` has no third-party modules to fetch;
if dependencies are added, their `go.sum` should be copied with `go.mod`.

I built two otherwise equivalent builder-only Dockerfiles without cache,
appended the same comment to `main.go` in two temporary source copies, then
rebuilt with cache enabled. Both used the same Go image and stripped build flags.

| Strategy | Initial build | Source-change rebuild |
|---|---:|---:|
| COPY all source, download modules, build | 15.66 s | 15.17 s |
| COPY go.mod, download modules, COPY source, build | 15.84 s | 13.39 s |

[Bad initial](evidence/lab6/cache-bad-initial.txt),
[bad rebuild](evidence/lab6/cache-bad-rebuild.txt),
[good initial](evidence/lab6/cache-good-initial.txt), and
[good rebuild](evidence/lab6/cache-good-rebuild.txt) preserve the actual logs.
The good rebuild explicitly reused the download layer. These are single-run
measurements, not a statistical benchmark; with no external dependencies the
timing difference is small and subject to host noise.

### b) Why disable CGO

`CGO_ENABLED=0` prevents dependencies on C libraries and their dynamic linker.
A dynamically linked executable copied into distroless-static can fail to start
with a misleading file-not-found error because the required loader is absent.
Leaving CGO enabled does not always produce dynamic linkage; the outcome depends
on imported packages and build configuration. The recorded `file` output
confirms that this application binary is statically linked.

### c) What distroless-static contains

Distroless-static supplies minimal runtime files such as CA certificates,
timezone data and user information, without a shell, compiler or package manager.
The nonroot variant provides UID 65532. Removing unnecessary packages reduces
the attack surface and OS-package vulnerability exposure, but does not remove
vulnerabilities compiled into the application's Go standard library.

### d) Build flags

`-s` omits the symbol table and debug information; `-w` omits DWARF debugging
information. They reduce binary size at the cost of debugger visibility.
`-trimpath` removes filesystem paths from the executable, reducing machine-specific
metadata and improving reproducibility; source paths become less useful for
local debugging. These flags alone do not pin a mutable base-image tag.

## Task 2 — Compose, health and persistence

The root [compose.yaml](../compose.yaml) defines the `quicknotes` service,
builds `./app`, tags `quicknotes:lab6`, publishes `127.0.0.1:8080:8080`, sets
all three environment variables, mounts `quicknotes-data:/data`, and uses
`restart: unless-stopped`. The [resolved configuration](evidence/lab6/compose-config.txt)
and [healthy service output](evidence/lab6/compose-healthy.txt) are included.

### e) Healthcheck without a shell

The exec-form check `["CMD", "/healthcheck"] runs a small static Go HTTP client
already in the runtime image. It requests `/health`, enforces a two-second client
timeout, and exits nonzero on a connection error or non-2xx response. The check
has no write side effects and does not mistake a live process for a healthy API.

### f) Named-volume lifecycle and actual persistence test

```bash
docker compose up --build -d
curl -fsS -X POST -H 'Content-Type: application/json' \
  -d '{"title":"durable","body":"survive a restart"}' http://127.0.0.1:8080/notes
curl -fsS http://127.0.0.1:8080/notes
docker compose down
docker compose up -d
# Wait for healthy, then repeat GET /notes.
docker compose down -v
docker compose up -d
# Wait for healthy, then repeat GET /notes.
```

The [POST](evidence/lab6/persistence-post.txt) created note 5, titled `durable`.
It is present [before down](evidence/lab6/persistence-before-down.txt) and
[after down/up](evidence/lab6/persistence-after-up.txt). After
[down -v](evidence/lab6/persistence-down-v.txt), the
[fresh result](evidence/lab6/persistence-after-volume-delete.txt) contains only
the four seed notes; the durable note is absent.
Ordinary `down` removes containers and the Compose network but retains the named
volume. `down -v` explicitly removes it; explicit volume removal or deleting
Docker's storage also destroys the data. A volume is persistence, not a backup.

### g) depends_on and readiness

Short-form `depends_on` orders service startup; it does not wait for an application
to accept requests. A client can therefore start before its database is ready
and fail its first connection. `condition: service_healthy` can wait for the
dependency's healthcheck, while clients still need retry handling for later failures.

## Bonus — Six security defaults

All runtime settings are in the `services.quicknotes` block of
[compose.yaml](../compose.yaml). The following commands were run with `sudo`
where required by the host's Docker socket permissions.

| Control | Verification and recorded outcome |
|---|---|
| Nonroot | `docker inspect quicknotes:lab6 --format '{{.Config.User}}'`: [nonroot:nonroot](evidence/lab6/security-user.txt) |
| Distroless, no shell | `docker export <container> \| tar -tf -`: [filesystem listing](evidence/lab6/runtime-files.txt) and [absence of sh/bash/dash/ash/busybox](evidence/lab6/security-no-shell.txt) |
| Drop all capabilities | Inspect `.HostConfig.CapDrop`: [ALL](evidence/lab6/security-cap-drop.txt) |
| Read-only root | Inspect `.HostConfig.ReadonlyRootfs`: [true](evidence/lab6/security-readonly-inspect.txt); actual write probe: [read-only file system](evidence/lab6/security-readonly-enforced.txt) |
| No new privileges | Inspect `.HostConfig.SecurityOpt`: [no-new-privileges:true](evidence/lab6/security-no-new-privileges.txt) |
| Vulnerability scan | Trivy 0.59.1 completed: [full scan](evidence/lab6/trivy.txt) |

The prescribed `docker compose exec -T quicknotes sh` hung on this host, so its
timeout was not counted as proof of a missing shell. The exported filesystem
listing provides that evidence instead. The write probe used:

```bash
docker exec --user 0 <container> /healthcheck --expect-write-failure /etc/lab6-test
```

It returned `write blocked as expected: open /etc/lab6-test: read-only file system`.
UID 0 was used only for this probe so ordinary nonroot directory permissions
could not explain the failure. The application still runs as nonroot.
`/data` remains writable through its named volume and `/tmp` is a bounded
[tmpfs with noexec/nosuid/nodev](evidence/lab6/security-tmpfs.txt).

### Trivy results and interpretation

```bash
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy:0.59.1 image --severity HIGH,CRITICAL --no-progress quicknotes:lab6
```

| Target | HIGH | CRITICAL |
|---|---:|---:|
| Debian 12.15 runtime packages | 0 | 0 |
| healthcheck Go binary | 19 | 0 |
| quicknotes Go binary | 19 | 0 |

The Go findings refer to the embedded Go 1.24.13 standard library in each binary,
so the per-binary counts must not be presented as 38 distinct vulnerabilities.
The scan succeeded; the image is not vulnerability-free. Fixed-version guidance
in the scan points to newer Go releases. The lab requires a Go 1.24 builder;
a production remediation would update the toolchain, rebuild and rescan.
This lab performs the explicitly permitted one-off scan; CI integration is
deferred to Lab 9.

Dropping all capabilities gives this application strong value for one small YAML
setting because serving HTTP on port 8080 needs no Linux capabilities.
`no-new-privileges` reinforces that choice by preventing exec-based privilege gains.
A read-only root filesystem limits unintended changes while the named volume
preserves the application's legitimate writes. Minimal images and scanning
complement these runtime controls, but none alone proves that escape is impossible.

## Submission status

- [x] Multi-stage runtime below 25 MB, nonroot and static binaries verified.
- [x] HTTP health and notes endpoints tested directly and through Compose.
- [x] Named-volume persistence and deliberate reset demonstrated.
- [x] All seven design questions and security analysis included.
- [x] Runtime controls and actual Trivy findings documented.
- [ ] Signed upstream PR published.
- [ ] PR URL submitted through Moodle.
