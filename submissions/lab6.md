# Task 1

## Design questions

1. Why does layer-order matter?

Answer:

`COPY . . && go mod download && go build` built for 4.8s, rebuilt for 4.3s without caching `go mod download`. 

`COPY go.mod go.sum ./ && go mod download && COPY . . && go build` built for 4.3s, rebuilt for 4.1s with cached `go mod download`.

Layer-order matter since if `go mod download` is time-consuming operation, we can skip it if we've done it before, the result is the same, and it is separated operation in Dockerfile.

0.4s

2. Why CGO_ENABLED=0? What happens in distroless-static if you forget it?

Answer: Setting `CGO_ENABLED=0` forces Go to produce a statically linked binary with zero external shared library dependencies. If you forget it on `distroless/static`, the container fails with `exec /bin/qn: no such file or directory` — the binary exists, but the dynamic linker (`ld-linux`) it needs does not, since `distroless/static` ships no libc.

3. What is gcr.io/distroless/static:nonroot? What's in it, what isn't, and why does that matter for CVEs?

Answer:

What it is: A Google-maintained minimal base image containing only what a statically linked binary needs to run — nothing more.

What's in it: CA certificates, tzdata, /etc/passwd and /etc/group with a nonroot user (uid 65532).

What isn't in it: shell, libc, dynamic linker, package manager, or any standard OS utilities.

Why does that matter for CVEs:
Every package in a container image is a potential CVE surface. Scanners like Trivy or Grype report vulnerabilities per installed package.

Alpine ships ~20 packages by default. debian:slim ships ~80+. Each one can have CVEs.

distroless/static ships essentially zero userspace packages.

4. -ldflags='-s -w' and -trimpath: what does each flag do, and what's the cost?

Answer:
- `-s` strips the symbol table — removes function names and addresses used by debuggers. Cost: `pprof` symbol lookup breaks; stack traces lose function names.
- `-w` strips DWARF debug info — removes line numbers and type info used by `dlv` / `gdb`. Cost: debugger attach no longer works.
- `-trimpath` removes absolute build-machine paths from the binary — stack traces show `app/main.go` instead of `/home/user/projects/app/main.go`. Cost: stack traces are less specific (no absolute path), but builds become reproducible and paths aren't leaked into the binary.

Combined, `-s -w` reduce binary size by ~20–30%. `-trimpath` adds negligible size change.

## Building and running container

Input: `docker images quicknotes:lab6`

Output:
```
quicknotes   lab6      470bbef4ae24   About an hour ago   5.51MB
```

Input: `docker inspect quicknotes:lab6 | jq '.[0].Config'`

Output:
```
{
  "Cmd": null,
  "Entrypoint": [
    "/bin/qn"
  ],
  "Env": [
    "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
  ],
  "ExposedPorts": {
    "8080/tcp": {}
  },
  "Labels": null,
  "OnBuild": null,
  "User": "",
  "Volumes": null,
  "WorkingDir": "/"
}
```

Input: `docker images golang:1.24.5`

```
REPOSITORY   TAG       IMAGE ID       CREATED         SIZE
golang       1.24.5    27480458d896   11 months ago   860MB
```

## Dockerfile

```dockerfile
FROM golang:1.24.5 AS build

RUN groupadd -r appgroup && useradd -r -g appgroup -u 65532 nonroot

WORKDIR /app

COPY --chown=nonroot:appgroup app /app/

RUN go mod download

RUN CGO_ENABLED=0 go build -ldflags="-s -w" -trimpath -o /bin/qn .

FROM scratch

COPY --from=build /bin/qn /bin/qn

USER 65532

EXPOSE 8080

ENTRYPOINT ["/bin/qn"]
```

# Task 2

## Design questions

1. Distroless has no shell. How do you healthcheck it?

`scratch` contains only `/bin/qn`. There is no shell, no wget, no curl, no nc — nothing to probe the HTTP endpoint from inside the container.

Setting test: ["NONE"] disables the test entirely. Docker marks the container healthy as soon as the process is running, and restart: unless-stopped handles the crash case — if /bin/qn exits, Docker restarts it automatically.

2. Why does volumes: [quicknotes-data:/data] survive docker compose down? And what does destroy it?

Answer: `docker compose down` does not remove volumes, therefore data is persistent. If we run `docker compose down -v`, volumes will be deleted and data will be lost.

3. `depends_on` without `condition: service_healthy` — what does it actually wait for? What's the bug it can cause?

Answer: without a condition, depends_on only waits for the dependent container to start — meaning Docker has created the container and the process has launched. It does not wait for the service to be ready to accept connections. 
The bug: if service B depends_on service A (e.g. a database), B starts immediately after A's process launches. A may still be initializing — running migrations, loading data, binding its port. B tries to connect, gets a connection refused, and crashes or enters a broken state.

The fix:
```
depends_on:
  quicknotes:
    condition: service_healthy
```
This makes Docker wait until the healthcheck passes before starting the dependent service. It only works if the dependency actually has a healthcheck defined — which is one more reason a real healthcheck matters beyond just monitoring.

## Persistence

Input:
```
docker compose up --build -d
sleep 3
curl -X POST -H 'Content-Type: application/json' \
  -d '{"title":"durable","body":"survive a restart"}' \
  http://localhost:8080/notes
curl -s http://localhost:8080/notes | grep durable
```

Output:
```
{"id":1,"title":"durable","body":"survive a restart","created_at":"2026-06-23T17:40:29.479735512Z"}
[{"id":1,"title":"durable","body":"survive a restart","created_at":"2026-06-23T17:40:29.479735512Z"}]
```

Input:
```
docker compose down                 # NOT `down -v`
docker compose up -d
sleep 3
curl -s http://localhost:8080/notes | grep durable
```

Output:
```
[{"id":1,"title":"durable","body":"survive a restart","created_at":"2026-06-23T17:40:29.479735512Z"}]
```

Input:
```
docker compose down -v              # NOW the volume dies
docker compose up -d
sleep 3
curl -s http://localhost:8080/notes | grep durable
```

Output: nothing

## docker-compose

```yaml
services:
  quicknotes:
    build:
      context: .
    image: quicknotes:lab6
    ports:
      - "8080:8080"
    volumes:
      - quicknotes-data:/data
    environment:
      ADDR: ":8080"
      DATA_PATH: /data/notes.json
      SEED_PATH: /seed.json
    healthcheck:
      test: ["NONE"]
      interval: 30s
      timeout: 5s
      retries: 3
      start_period: 5s
    restart: unless-stopped

volumes:
  quicknotes-data:
```
