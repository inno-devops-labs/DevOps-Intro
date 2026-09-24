# Lab 6 Submission — Containers

## Task 1 — Multi-Stage Dockerfile

### Dockerfile

```dockerfile
FROM golang:1.24-alpine AS builder

WORKDIR /src

COPY go.mod ./
RUN go mod download

COPY *.go ./
COPY seed.json ./
RUN mkdir -p /src/data

RUN CGO_ENABLED=0 go build \
    -trimpath \
    -ldflags='-s -w' \
    -o /quicknotes .

RUN cat > /tmp/healthcheck.go <<'GOEOF'
package main

import (
	"net/http"
	"os"
	"time"
)

func main() {
	client := http.Client{Timeout: 2 * time.Second}
	resp, err := client.Get("http://127.0.0.1:8080/health")
	if err != nil {
		os.Exit(1)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		os.Exit(1)
	}
}
GOEOF

RUN CGO_ENABLED=0 go build \
    -trimpath \
    -ldflags='-s -w' \
    -o /healthcheck /tmp/healthcheck.go

FROM gcr.io/distroless/static-debian12:nonroot

COPY --from=builder /quicknotes /quicknotes
COPY --from=builder /healthcheck /healthcheck
COPY --from=builder /src/seed.json /seed.json
COPY --from=builder --chown=65532:65532 /src/data /data

EXPOSE 8080

USER nonroot:nonroot

ENTRYPOINT ["/quicknotes"]
```

### Image size

```text
$ sudo docker images quicknotes:lab6

IMAGE             ID             DISK USAGE   CONTENT SIZE
quicknotes:lab6   334a94af3b71       22.6MB         5.62MB
```

The final image is below the required 25 MB limit.

For comparison, the Go builder image is much larger:

```text
$ sudo docker images golang:1.24-alpine

IMAGE                ID             DISK USAGE   CONTENT SIZE
golang:1.24-alpine   8bee1901f1e5        395MB         83.5MB
```

### Image configuration

```text
$ sudo docker inspect quicknotes:lab6 | jq '.[0].Config | {User, ExposedPorts, Entrypoint}'

{
  "User": "nonroot:nonroot",
  "ExposedPorts": {
    "8080/tcp": {}
  },
  "Entrypoint": [
    "/quicknotes"
  ]
}
```

### Runtime verification

```text
$ curl -s http://localhost:8080/health
{"notes":0,"status":"ok"}

$ curl -s http://localhost:8080/notes
[]
```

### Design questions

#### a) Why does layer order matter?

Docker can reuse unchanged layers from its build cache. If `COPY . .` happens before `go mod download`, any source-code change invalidates the copy layer and everything after it, including dependency download.

I compared both approaches after making the same temporary source change.

Bad ordering:

```dockerfile
COPY . .
RUN go mod download
RUN go build
```

Result:

```text
real    0m9.819s
```

Cache-friendly ordering:

```dockerfile
COPY go.mod ./
RUN go mod download
COPY *.go ./
RUN go build
```

Result:

```text
real    0m7.966s
```

With the better ordering, the `go mod download` layer remained cached after changing source code. The difference in this small project is modest because there are currently no external Go module dependencies, but the benefit becomes much larger for projects with substantial dependency downloads.

#### b) Why `CGO_ENABLED=0`?

`CGO_ENABLED=0` makes the Go binary statically linked and removes its dependency on the system C runtime. This is necessary for a distroless-static runtime because the image does not contain a normal dynamic linker or C runtime. Without a static binary, the application may fail to start even though the binary itself exists.

#### c) What is `gcr.io/distroless/static:nonroot`?

A distroless static image contains only the minimal runtime files required to execute a static application. It does not include a shell, package manager, compiler, or normal Linux userland tools. The `nonroot` variant also runs with an unprivileged user. Having fewer packages reduces image size and reduces the number of components that can contain vulnerabilities.

#### d) What do `-ldflags='-s -w'` and `-trimpath` do?

`-ldflags='-s -w'` strips the symbol table and DWARF debugging information from the compiled binary, reducing its size. The cost is less debugging information in the produced executable.

`-trimpath` removes local filesystem paths from the compiled binary, which improves reproducibility and avoids exposing build-machine paths.

---

## Task 2 — Compose, Healthcheck and Persistent Volume

### compose.yaml

```yaml
services:
  quicknotes:
    build:
      context: ./app
    image: quicknotes:lab6
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
      interval: 5s
      timeout: 3s
      retries: 3
      start_period: 2s
    restart: unless-stopped

volumes:
  quicknotes-data:
```

After startup:

```text
NAME                        IMAGE             COMMAND         SERVICE      STATUS
devops-intro-quicknotes-1   quicknotes:lab6   "/quicknotes"   quicknotes   Up (healthy)
```

```text
$ curl -s http://localhost:8080/health
{"notes":4,"status":"ok"}
```

### Persistence test

First I created a new note:

```text
$ curl -X POST \
  -H 'Content-Type: application/json' \
  -d '{"title":"durable","body":"survive a restart"}' \
  http://localhost:8080/notes

{"id":5,"title":"durable","body":"survive a restart","created_at":"2026-09-24T21:04:54.600713681Z"}
```

The note existed:

```text
"title":"durable","body":"survive a restart"
```

Then I stopped Compose without deleting volumes:

```text
$ sudo docker compose down
$ sudo docker compose up -d
```

After restarting, the durable note was still present:

```text
"title":"durable","body":"survive a restart"
```

Then I removed the Compose stack together with its volume:

```text
$ sudo docker compose down -v
$ sudo docker compose up -d
```

Verification:

```text
$ curl -s http://localhost:8080/notes | grep durable || echo "durable note is gone"
durable note is gone
```

This proves that the named volume preserves application state across normal container recreation, but deleting the volume removes that state.

### Design questions

#### e) Distroless has no shell. How is the healthcheck implemented?

I compiled a small static Go healthcheck binary during the builder stage and copied it into the final image as `/healthcheck`.

Compose runs it directly using exec form:

```yaml
healthcheck:
  test: ["CMD", "/healthcheck"]
```

The binary sends an HTTP request to `http://127.0.0.1:8080/health` and exits with status 0 only when it receives HTTP 200. This avoids requiring a shell, `curl`, or `wget` in the distroless runtime image.

#### f) Why does the named volume survive `docker compose down`?

`docker compose down` removes containers and the Compose network, but named volumes are retained because their lifecycle is separate from the container lifecycle. Therefore `/data/notes.json` remains available when the container is recreated.

Running:

```bash
docker compose down -v
```

explicitly removes the named volume, which destroys the persisted data.

#### g) What does `depends_on` without `condition: service_healthy` wait for?

Without `condition: service_healthy`, `depends_on` only controls container startup order. It does not guarantee that the dependency is ready to accept requests.

This can create a race condition where one service starts immediately after another container has been launched, but the dependency is still initializing and cannot yet serve requests.
