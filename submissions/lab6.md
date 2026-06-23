# Lab 6 — Task 1

## Dockerfile

File: `app/Dockerfile`

```dockerfile
FROM golang:1.24.0-alpine3.21 AS builder

WORKDIR /src

COPY go.mod ./
RUN go mod download

COPY *.go ./
COPY seed.json ./

RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /out/quicknotes .

FROM gcr.io/distroless/static:nonroot

COPY --from=builder /out/quicknotes /quicknotes
COPY --from=builder /src/seed.json /seed.json

ENV ADDR=:8080 \
    DATA_PATH=/data/notes.json \
    SEED_PATH=/seed.json

USER 65532:65532
EXPOSE 8080

ENTRYPOINT ["/quicknotes"]
```

## Image size

```text
REPOSITORY   TAG       IMAGE ID       CREATED         SIZE
quicknotes   lab6      202d7cf66323   8 seconds ago   14.2MB
```

## `docker inspect` config excerpt

Equivalent excerpt from `docker inspect quicknotes:lab6`:

```json
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

## Builder image size comparison

```text
REPOSITORY   TAG                 IMAGE ID       CREATED         SIZE
golang       1.24.0-alpine3.21   2d40d4fc278d   16 months ago   385MB
```

The final runtime image is `14.2MB`, compared with `385MB` for the builder base image.

## Build and run verification

```text
$ docker run -d --rm -p 8080:8080 -v "$PWD/data:/data" quicknotes:lab6
$ curl -s http://localhost:8080/health
{"notes":7,"status":"ok"}
```

## Design answers

### a) Why does layer order matter?

Docker reuses cached layers only until the first instruction whose inputs change. If the Dockerfile does `COPY . .` before `go mod download`, then any source edit invalidates the `COPY . .` layer and forces Docker to run `go mod download` again, even though dependencies did not change.

If the Dockerfile copies `go.mod` first, runs `go mod download`, and only then copies the source files, a source-only change keeps the dependency layer cached. On this app the rebuild time difference is small because the module has no external dependencies, but the cache behavior is still correct.

Measured rebuilds after a source-only edit:

```text
Bad order:  COPY . . -> go mod download -> go build    real 8.36s
Good order: COPY go.mod -> go mod download -> COPY src -> go build    real 8.04s
```

Observed step behavior:

- Bad order: `COPY . .`, `RUN go mod download`, and `RUN go build` all reran.
- Good order: `COPY go.mod` and `RUN go mod download` stayed cached; only source copy and build reran.

In a real service with many downloaded modules, the good order saves much more time because it avoids network work on every source change.

### b) Why `CGO_ENABLED=0`?

`CGO_ENABLED=0` forces a pure-Go static binary that does not need a dynamic linker or C runtime in the final image. That is exactly what a distroless static runtime expects.

If you forget it and the build produces a dynamically linked binary, the container usually fails to start in `gcr.io/distroless/static:nonroot` because the required loader or shared libraries are not present. The common symptom is an error like `no such file or directory` even though the binary file exists.

### c) What is `gcr.io/distroless/static:nonroot`?

It is a minimal runtime image for statically linked programs. It contains only the small set of runtime files needed to launch the application safely as a non-root user, such as basic identity metadata and CA certificates.

It does not contain a shell, package manager, compiler, or normal debugging tools. There is no `sh`, no `apt`, no `apk`, and no extra userland utilities.

That matters for CVEs because fewer installed packages means a much smaller attack surface and fewer OS-level vulnerabilities to scan, patch, or exploit. It does not remove bugs from the application itself, but it does remove a lot of unnecessary operating-system baggage.

### d) What do `-ldflags='-s -w'` and `-trimpath` do, and what is the cost?

`-ldflags='-s -w'` strips the symbol table and DWARF debug information from the binary. The main benefit is a smaller image. The cost is worse post-build debugging because the binary carries less debug metadata.

`-trimpath` removes local filesystem paths from the compiled binary. That improves reproducibility and avoids leaking machine-specific build paths. The cost is that stack traces and debug output are slightly less informative because absolute source paths are no longer embedded.