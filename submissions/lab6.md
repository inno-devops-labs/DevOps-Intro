# Lab 6 — Containers: Dockerize QuickNotes

The submitted files are [`app/Dockerfile`](../app/Dockerfile), [`app/.dockerignore`](../app/.dockerignore), and [`compose.yaml`](../compose.yaml). The image was built and tested with Docker Engine 29.4.0 and Compose 5.1.1 on Windows with the Linux container backend. Port 8080 on this host was already occupied by PostgreSQL, so the checks below set `QUICKNOTES_HOST_PORT=28080`; the committed Compose default remains `127.0.0.1:8080`.

## Task 1 — Small multi-stage image

The builder is the official `golang:1.24.13-alpine` image. It copies `go.mod` and runs `go mod download` before copying the source. The final stage is `gcr.io/distroless/static-debian13:nonroot`, and it contains the statically linked, stripped binary, `seed.json`, and a `/data` directory owned by UID 65532. It has no shell or Go toolchain.

```text
docker images quicknotes:lab6 --format '{{.Repository}}:{{.Tag}} {{.Size}}'
quicknotes:lab6 15.7MB

docker images golang:1.24.13-alpine --format '{{.Repository}}:{{.Tag}} {{.Size}}'
golang:1.24.13-alpine 395MB

docker image inspect quicknotes:lab6 --format 'user={{.Config.User}} entrypoint={{json .Config.Entrypoint}} exposed={{json .Config.ExposedPorts}}'
user=65532:65532 entrypoint=["/quicknotes"] exposed={"8080/tcp":{}}
```

The final image is 15.7 MB, below the 25 MB limit. `go test ./...` passed inside `golang:1.24.13-alpine`. A direct `docker run --rm -d -p 127.0.0.1:28080:8080 quicknotes:lab6` returned HTTP 200 and `{"notes":4,"status":"ok"}` from `/health`; `/notes` returned the four seeded notes.

### Design answers

**a) Layer order.** Docker reuses a layer only while its inputs remain unchanged. With `COPY . .` before `go mod download`, a source edit invalidates the dependency step. Copying `go.mod` first lets that step stay cached when only Go source changes. QuickNotes currently has no external Go modules, so the measurable benefit is small; the controlled rebuild measurements and the alternative Dockerfile are recorded below.

I primed both strategies on the same source tree, inserted the same one-line comment into `main.go`, and timed each rebuild with PowerShell's `Stopwatch` and `docker build --quiet`. I then removed the benchmark comment; it is not part of the submission.

| Strategy | Dockerfile | Rebuild after the source edit |
|---|---|---:|
| `COPY . .` before `go mod download` | [`lab6-naive.Dockerfile`](evidence/lab6-naive.Dockerfile) | 20.37 s |
| `COPY go.mod`, download, then `COPY . .` | [`app/Dockerfile`](../app/Dockerfile) | 18.29 s |

The optimized order saved 2.08 seconds in this one run. Most of the remaining time was recompilation; this module has no dependencies to download, and hosted or local runner load can vary between runs.

**b) Static build.** `CGO_ENABLED=0` prevents C-linked code from requiring a dynamic loader or libc. Without a static binary, a `distroless/static` container may fail at startup with a misleading “no such file or directory” error for the absent loader.

**c) Distroless static nonroot.** The distroless static runtime has only the minimal files needed by a static application, including certificates and basic user data; it has no shell, package manager, or compiler. The `nonroot` variant sets UID 65532. The smaller runtime reduces packages and potential OS CVEs, although it cannot remove vulnerabilities compiled into the Go binary.

**d) Build flags.** `-ldflags="-s -w"` removes symbol and DWARF debug tables from the executable; `-trimpath` removes local source paths from build output. This saves space and makes builds less host-dependent, at the cost of less useful native stack and symbol information when debugging a production binary.

## Task 2 — Compose, health, and persistence

The `quicknotes` service builds from `./app`, tags `quicknotes:lab6`, publishes guest port 8080 on the host loopback interface, sets `ADDR`, `DATA_PATH`, and `SEED_PATH`, restarts unless stopped, and mounts the named `quicknotes-data` volume at `/data`. The Compose healthcheck runs `/quicknotes healthcheck`: the application binary makes a local HTTP request to `/health` and exits nonzero unless it receives 200. This works without a shell or `curl` in the runtime image. The observed container status was `Up ... (healthy)`.

The persistence test used this exact Compose project and host port 28080:

| Step | Command and observed result |
|---|---|
| Create | `POST /notes` with `{"title":"durable","body":"survive a restart"}` returned note ID 5. `GET /notes` showed that note. |
| Recreate | `docker compose down` left volume `quicknotes-lab6_quicknotes-data` present. After `docker compose up -d`, `GET /notes` still returned note ID 5. |
| Remove volume | `docker compose down -v` removed that named volume. After `docker compose up -d`, `GET /notes` returned four seeded notes: `durable_count=0`. |

**e) Healthcheck without a shell.** The Go executable has a `healthcheck` mode that performs a timeout-bound HTTP GET on its own `/health` endpoint. An exec-form `test: ["CMD", "/quicknotes", "healthcheck"]` checks application readiness rather than mere process existence; it uses no external tools and has no side effects on notes.

**f) Volume lifetime.** `down` removes the container and network, but named volumes are independent Docker objects, so the notes file remains. `down -v` explicitly removes declared named volumes; `docker volume rm` would also delete it.

**g) Dependency readiness.** Short-form `depends_on` waits for a dependency container to be started, not for it to accept requests. A dependent service can therefore start too early and fail its first connection. `condition: service_healthy` waits for the dependency healthcheck to pass.

## Bonus — Six security defaults

The committed service runs as nonroot in a distroless image, drops every Linux capability, has a read-only root filesystem with a small `/tmp` tmpfs and the writable `/data` volume, and sets `no-new-privileges`. Trivy was run against the final image.

| Control | Verification output |
|---|---|
| Nonroot | `docker image inspect quicknotes:lab6 --format '{{.Config.User}}'` → `65532:65532` |
| No shell | `docker compose exec -T quicknotes sh` → `exec: "sh": executable file not found in $PATH` (exit 127) |
| Capabilities | `docker inspect quicknotes-lab6-quicknotes-1 --format '{{.HostConfig.CapDrop}}'` → `[ALL]` |
| Read-only root | `docker cp app/seed.json quicknotes-lab6-quicknotes-1:/etc/lab6-write-test` → `container rootfs is marked read-only` (exit 1). `/tmp` is tmpfs; `/data` is the named volume. |
| No new privileges | `docker inspect quicknotes-lab6-quicknotes-1 --format '{{.HostConfig.SecurityOpt}}'` → `[no-new-privileges:true]` |

Trivy 0.59.1 scanned `quicknotes:lab6` with current vulnerability data and `--severity HIGH,CRITICAL --scanners vuln`; the captured [scan output](evidence/lab6-trivy.txt) is included. Its Debian 13.7 runtime result was **0 HIGH, 0 CRITICAL**. The Go 1.24.13 binary still had **19 HIGH, 0 CRITICAL** findings in the standard library; these were reported rather than hidden. Updating to the latest permitted Go 1.24 patch removed the one CRITICAL finding present with Go 1.24.5, but further remediation requires moving to a supported Go minor version beyond this lab's 1.24 builder constraint.

For this application, `cap_drop: [ALL]` gives the largest immediate reduction in kernel privilege for one Compose setting: QuickNotes needs no capabilities to listen on port 8080 or write its data volume. Nonroot and the read-only root filesystem limit damage if the process is compromised. `no-new-privileges` blocks gaining extra rights through exec, while the scan exposes risks in dependencies that these runtime controls cannot fix.
