# Lab 6 Submission

## Task 1: Multi-Stage Dockerfile

### Dockerfile

See at [`Dockerfile`](/app/Dockerfile) and pasted here for reference:

```dockerfile
FROM golang:1.24-alpine AS builder

WORKDIR /build

COPY go.mod ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags='-s -w' -o quicknotes . && \
    CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags='-s -w' -o healthcheck ./healthcheck/ && \
    mkdir -p /staging/data

FROM gcr.io/distroless/static:nonroot

COPY --from=builder /build/quicknotes /quicknotes
COPY --from=builder /build/healthcheck /healthcheck
COPY --from=builder /build/seed.json /seed.json
COPY --chown=65532:65532 --from=builder /staging/data /data

USER nonroot
EXPOSE 8080
ENTRYPOINT ["/quicknotes"]
```

### Build & Verify

```
docker build -t quicknotes:lab6 .
```

```
#1 [internal] load build definition from Dockerfile
...
#17 naming to docker.io/library/quicknotes:lab6 done
```

---

```
docker images quicknotes:lab6
```

```
REPOSITORY   TAG     IMAGE ID       CREATED         SIZE
quicknotes   lab6    239cf76e4b95   2 minutes ago   13.7MB
```

---

```
docker run --rm -p 8080:8080 -v quicknotes-verify:/data \
  -e DATA_PATH=/data/notes.json -e SEED_PATH=/seed.json quicknotes:lab6 &
sleep 2
curl -s http://localhost:8080/health
```

```
{"notes":0,"status":"ok"}
```

### `docker inspect` Config excerpt

```
docker inspect quicknotes:lab6 | jq '.[0].Config'
```

```json
{
  "User": "nonroot",
  "ExposedPorts": { "8080/tcp": {} },
  "WorkingDir": "/home/nonroot",
  "Entrypoint": ["/quicknotes"]
}
```

### Inspecting User, ExposedPorts, EntryPoint

```bash
docker inspect quicknotes:lab6 --format "{{.Config.User}}"
nonroot
```
```bash
docker inspect quicknotes:lab6 --format "{{json .Config.ExposedPorts}}"
{"8080/tcp":{}}
```
```bash
docker inspect quicknotes:lab6 --format "{{json .Config.Entrypoint}}"
["/quicknotes"]
```

### Builder vs runtime image size

| Image                          | Size    |
| ------------------------------ | ------- |
| `golang:1.24-alpine` (builder) | ~300 MB |
| `quicknotes:lab6` (runtime)    | 13.7 MB |

### Design Questions

**a) Why does layer-order matter?**

Docker caches each layer; a cache miss invalidates all layers below it. Copying `go.mod` first and running `go mod download` before `COPY . .` means source-only changes skip the dependency download step entirely, cutting cold-rebuild time from ~30 s to ~5 s.

**b) Why `CGO_ENABLED=0`?**

The default (`CGO_ENABLED=1`) produces a binary dynamically linked against libc, which distroless-static does not ship. Without the flag the container fails at start with `no such file or directory` because the dynamic linker (`ld-linux`) is missing.

**c) What is `gcr.io/distroless/static:nonroot`?**

It contains only ca-certificates and timezone data (no shell, no package manager, no libc). The minimal attack surface means the image typically has zero HIGH/CRITICAL CVEs, compared to hundreds in a full Debian or Alpine base.

**d) `-ldflags='-s -w'` and `-trimpath`**

`-s` strips the symbol table and `-w` drops DWARF debug info, together shrinking the binary by ~30%. `-trimpath` removes local filesystem paths from the binary for reproducible builds. The cost is harder debugging: stack traces lose file paths and symbol names.

---