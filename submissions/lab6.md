# Lab 6 Submission

## Task 1 - Multi-Stage Dockerfile, <= 25 MB

### Dockerfile

`app/Dockerfile`:

```dockerfile
FROM golang:1.24-alpine AS builder

WORKDIR /src

COPY go.mod ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -trimpath -ldflags="-s -w" -o /out/quicknotes .

FROM gcr.io/distroless/static:nonroot

WORKDIR /app

COPY --from=builder /out/quicknotes /quicknotes
COPY --from=builder /src/seed.json /app/seed.json

USER nonroot:nonroot

EXPOSE 8080

ENTRYPOINT ["/quicknotes"]
```

### Final image size

Command:

```bash
docker images quicknotes:lab6
```

Output:

```text
REPOSITORY   TAG       IMAGE ID       CREATED          SIZE
quicknotes   lab6      58d554af210b   25 minutes ago   8.08MB
```

The final image size is **8.08 MB**, which is below the required **25 MB** limit.

### Runtime verification

Command:

```bash
curl -s http://localhost:8080/health
```

Output:

```json
{"notes":8,"status":"ok"}
```

Command:

```bash
curl -s http://localhost:8080/notes
```

Output:

```json
[{"id":5,"title":"hello","body":"first POST","created_at":"2026-06-06T13:58:10.090960026Z"},{"id":6,"title":"hello","body":"first POST","created_at":"2026-06-07T10:40:15.531409717Z"},{"id":7,"title":"trace me","body":"in flight","created_at":"2026-06-16T07:07:22.002480556Z"},{"id":8,"title":"trace me","body":"in flight","created_at":"2026-06-16T07:13:08.030657439Z"},{"id":1,"title":"Welcome to QuickNotes","body":"This is the project you'll containerize, deploy, monitor, and harden across all 10 labs.","created_at":"2026-01-15T10:00:00Z"},{"id":2,"title":"Read app/main.go first","body":"Start by understanding the entry point — env vars, signal handling, graceful shutdown.","created_at":"2026-01-15T10:05:00Z"},{"id":3,"title":"DevOps mantra","body":"If it hurts, do it more often.","created_at":"2026-01-15T10:10:00Z"},{"id":4,"title":"Endpoint cheat-sheet","body":"GET /notes  GET /notes/{id}  POST /notes  DELETE /notes/{id}  GET /health  GET /metrics","created_at":"2026-01-15T10:15:00Z"}]
```

The container serves both `/health` and `/notes` successfully.

### Image config inspection

Command:

```bash
docker inspect quicknotes:lab6 | jq '.[0].Config'
```

Relevant output:

```json
{
  "User": "nonroot:nonroot",
  "ExposedPorts": {
    "8080/tcp": {}
  },
  "WorkingDir": "/app",
  "Entrypoint": [
    "/quicknotes"
  ]
}
```

Command:

```bash
docker inspect quicknotes:lab6 --format '{{ .Config.User }}'
```

Output:

```text
nonroot:nonroot
```

The image runs as the nonroot distroless user and exposes port `8080`.

### Base image size comparison

Command:

```bash
docker images golang:1.24-alpine
```

Output:

```text
REPOSITORY   TAG           IMAGE ID       CREATED        SIZE
golang       1.24-alpine   ebe4e0721205   4 months ago   262MB
```

Command:

```bash
docker images gcr.io/distroless/static:nonroot
```

Output:

```text
REPOSITORY                 TAG       IMAGE ID       CREATED        SIZE
gcr.io/distroless/static   nonroot   c9c1077449de   56 years ago   2.21MB
```

The builder image is **262 MB**, but it is not included in the final runtime image. The final image uses the much smaller distroless static runtime base and only copies in the compiled QuickNotes binary and `seed.json`.

### Layer cache comparison

Two Dockerfile strategies were tested.

Bad cache strategy:

```dockerfile
COPY . .
RUN go mod download
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -trimpath -ldflags="-s -w" -o /out/quicknotes .
```

Good cache strategy:

```dockerfile
COPY go.mod ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -trimpath -ldflags="-s -w" -o /out/quicknotes .
```

Bad cache build command:

```bash
time docker build -f Dockerfile.bad -t quicknotes:bad-cache .
```

Relevant output:

```text
[builder 3/5] COPY . .                                                                 0.0s
[builder 4/5] RUN go mod download                                                      0.1s
[builder 5/5] RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64     go build -trimpath ...      5.6s

real    0m6.009s
```

Good cache build command:

```bash
time docker build -f Dockerfile.good -t quicknotes:good-cache .
```

Relevant output:

```text
CACHED [builder 3/6] COPY go.mod ./                                                    0.0s
CACHED [builder 4/6] RUN go mod download                                               0.0s
[builder 5/6] COPY . .                                                                 0.0s
[builder 6/6] RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64     go build -trimpath ...      5.5s

real    0m5.725s
```

| Strategy | Captured rebuild time | Dependency layer behavior |
| --- | ---: | --- |
| Bad: `COPY . .` before `go mod download` | `6.009s` | `go mod download` ran again |
| Good: `COPY go.mod ./` before `go mod download` | `5.725s` | `go mod download` was cached |

The timing difference is small in this project because the Go module currently has no external dependencies. The important result is the layer behavior: in the good strategy, Docker reused the `go mod download` layer, while in the bad strategy it had to run again after the source context changed.

### Design question a: Why does layer order matter?

Docker caches each build layer. A layer can only be reused if that layer and all previous layers are unchanged.

In the bad strategy, `COPY . .` happens before `go mod download`. That means any source file change invalidates the copy layer, and Docker must rerun `go mod download`.

In the good strategy, only `go.mod` is copied before `go mod download`. If normal source files change but dependencies do not, Docker reuses the dependency download layer and only reruns the source copy and build steps.

### Design question b: Why `CGO_ENABLED=0`?

`CGO_ENABLED=0` tells Go to build a static binary that does not depend on C libraries or a dynamic linker.

This matters because `gcr.io/distroless/static:nonroot` is designed for static binaries. If the Go binary is dynamically linked, the container may fail at runtime with an error such as `no such file or directory`, even though the binary exists. That happens because the required dynamic linker or shared libraries are missing from the distroless static image.

### Design question c: What is `gcr.io/distroless/static:nonroot`?

`gcr.io/distroless/static:nonroot` is a minimal runtime image intended for statically linked applications.

It includes only the minimal files needed to run a static binary, plus the predefined nonroot user. It does not include a shell, package manager, compiler, Go toolchain, or normal Linux debugging tools.

This matters for security because fewer packages means a smaller attack surface and fewer possible CVEs. It also prevents common interactive debugging or exploitation paths such as running `sh` inside the container.

### Design question d: What do `-ldflags="-s -w"` and `-trimpath` do?

`-ldflags="-s -w"` passes options to the Go linker:

- `-s` removes the symbol table.
- `-w` removes DWARF debugging information.

This makes the binary smaller, but the cost is reduced debugging information.

`-trimpath` removes local filesystem paths from the compiled binary. This improves reproducibility because the binary does not contain machine-specific build paths. The cost is that stack traces and debug information may contain less detailed local path information.
