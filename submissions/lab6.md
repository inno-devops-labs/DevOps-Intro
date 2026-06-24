<h1>Task 1</h1>

```
#---------- Builder stage ----------

FROM golang:1.24-alpine AS builder

# WorkDir

WORKDIR /build

# copy go.mod and run

COPY go.mod ./
RUN go mod download

COPY . .


# CGO_ENABLED=0 — disable CGO 
# -ldflags='-s -w' — delete table symbol

RUN CGO_ENABLED=0 GOOS=linux go build \
    -ldflags='-s -w' \
    -trimpath \
    -o quicknotes .

# -------------------- Runtime stage --------------------
FROM gcr.io/distroless/static:nonroot

# copy bin from builder-stage

COPY --from=builder /build/quicknotes /quicknotes

# UID 65532 in distroless/static:nonroot

USER 65532:65532

# port
EXPOSE 8080

# exec-form
ENTRYPOINT ["/quicknotes"]

```

```docker build -t quicknotes:lab6 .```

DEPRECATED: The legacy builder is deprecated and will be removed in a future release.
            Install the buildx component to build images with BuildKit:
            https://docs.docker.com/go/buildx/

Sending build context to Docker daemon  32.77kB
Step 1/11 : FROM golang:1.24-alpine AS builder
 ---> 8bee1901f1e5
Step 2/11 : WORKDIR /build
 ---> Using cache
 ---> 3a3900d69d95
Step 3/11 : COPY go.mod ./
 ---> 89ec28a9a659
Step 4/11 : RUN go mod download
 ---> Running in 0f3cdbd3af17
go: no module dependencies to download
 ---> Removed intermediate container 0f3cdbd3af17
 ---> 1c5deacc2eb0
Step 5/11 : COPY . .
 ---> 0796c7fbd90e
Step 6/11 : RUN CGO_ENABLED=0 GOOS=linux go build     -ldflags='-s -w'     -trimpath     -o quicknotes .
 ---> Running in 11d26cb5a546
 ---> Removed intermediate container 11d26cb5a546
 ---> 48999180db7d
Step 7/11 : FROM gcr.io/distroless/static:nonroot
nonroot: Pulling from distroless/static
bdfd7f7e5bf6: Pulling fs layer
2780920e5dbf: Pulling fs layer
ebddc55facdc: Pulling fs layer
dd64bf2dd177: Pulling fs layer
7c12895b777b: Pulling fs layer
b839dfae01f6: Pulling fs layer
47de5dd0b812: Pulling fs layer
99515e7b4d35: Pulling fs layer
c172f21841df: Pulling fs layer
52630fc75a18: Pulling fs layer
99ba982a9142: Pulling fs layer
3214acf345c0: Pulling fs layer
d6b1b89eccac: Pulling fs layer
3214acf345c0: Download complete
52630fc75a18: Download complete
dd64bf2dd177: Download complete
2780920e5dbf: Download complete
b839dfae01f6: Download complete
ebddc55facdc: Download complete
7c12895b777b: Download complete
47de5dd0b812: Download complete
47de5dd0b812: Pull complete
d6b1b89eccac: Download complete
bdfd7f7e5bf6: Download complete
c172f21841df: Download complete
c172f21841df: Pull complete
99ba982a9142: Download complete
99515e7b4d35: Download complete
99ba982a9142: Pull complete
99515e7b4d35: Pull complete
2780920e5dbf: Pull complete
7c12895b777b: Pull complete
d6b1b89eccac: Pull complete
3214acf345c0: Pull complete
52630fc75a18: Pull complete
dd64bf2dd177: Pull complete
b839dfae01f6: Pull complete
ebddc55facdc: Pull complete
bdfd7f7e5bf6: Pull complete
Digest: sha256:963fa6c544fe5ce420f1f54fb88b6fb01479f054c8056d0f74cc2c6000df5240
Status: Downloaded newer image for gcr.io/distroless/static:nonroot
 ---> 963fa6c544fe
Step 8/11 : COPY --from=builder /build/quicknotes /quicknotes
 ---> 4e06adfe897f
Step 9/11 : USER 65532:65532
 ---> Running in 7ca5bd40c573
 ---> Removed intermediate container 7ca5bd40c573
 ---> b637dbefae84
Step 10/11 : EXPOSE 8080
 ---> Running in 1174636e8323
 ---> Removed intermediate container 1174636e8323
 ---> 00cd23a3ba73
Step 11/11 : ENTRYPOINT ["/quicknotes"]
 ---> Running in 889df7aa1ffa
 ---> Removed intermediate container 889df7aa1ffa
 ---> 3e56b235cfc0
Successfully built 3e56b235cfc0
Successfully tagged quicknotes:lab6

```docker images quicknotes:lab6```

IMAGE             ID             DISK USAGE   CONTENT SIZE   EXTRA
quicknotes:lab6   3e56b235cfc0       14.8MB         3.32MB   


```docker run --rm -p 8080:8080 -v "$PWD/data:/data" quicknotes:lab6 & sleep 2```

[2] 22666
docker: Error response from daemon: failed to set up container networking: driver failed programming external connectivity on endpoint mystifying_mestorf (2551b8de4cba1f3af30efb4c1e3305a39d13fa2bd86ebbca5dc591f51ef9bad4): Bind for :::8080 failed: port is already allocated

Run 'docker run --help' for more information
[2]+  Exit 125                docker run --rm -p 8080:8080 -v "$PWD/data:/data" quicknotes:lab6


```curl -s http://localhost:8080/health```

{"notes":0,"status":"ok"}

```docker stop $(docker ps -q --filter ancestor=quicknotes:lab6)```
2026/06/24 14:50:52 shutting down
ebf2ac84d37f



<h2>Questions:</h2>

```a) Why does layer-order matter? Show before/after rebuild times for two strategies: COPY . . && go mod download && go build vs COPY go.mod go.sum ./ && go mod download && COPY . . && go build```

Docker caches each layer. If a layer’s content hasn’t changed, Docker reuses the cache. Placing COPY go.mod go.sum and go mod download before copying the rest of the source code ensures that dependencies are re‑downloaded only when go.mod or go.sum change. The source code (COPY .) changes frequently, but because it comes after the dependency layer, the go mod download layer stays cached

```b) Why CGO_ENABLED=0? What happens in distroless-static if you forget it?```

<b>CGO_ENABLED=0 </b> forces the Go compiler to produce a statically linked binary that does not depend on the system’s C library (libc). It uses Go’s own network stack and system call wrappers.

```c) What is gcr.io/distroless/static:nonroot? What's in it, what isn't, and why does that matter for CVEs?```
<b>gcr.io/distroless/static:nonroot</b> is a minimal container image based on Debian, stripped down to the bare essentials.

```d) -ldflags='-s -w' and -trimpath: what does each flag do, and what's the cost?```

<b>-ldflags='-s'</b> Strips the symbol table (debugging symbols) <b>-ldflags='-w'</b> Strips DWARF debugging information <b>-trimpath</b> Removes absolute file paths from the binary


<h1>Task 2</h2>

```
services:
  quicknotes:
    build:
      context: ./app
      dockerfile: Dockerfile
    image: quicknotes:lab6
    container_name: quicknotes
    ports:
      - "8080:8080"
    volumes:
      - quicknotes-data:/data
    environment:
      - ADDR=:8080
      - DATA_PATH=/data/notes.json
      - SEED_PATH=/data/seed.json
    healthcheck:
      test: ["CMD", "/quicknotes", "-healthcheck"]   # или ["CMD-SHELL", "wget -qO- http://localhost:8080/health"]
      interval: 10s
      timeout: 5s
      retries: 3
      start_period: 5s
    restart: unless-stopped
    # Для продакшена — security hardening (см. Bonus, но мы не делаем)

volumes:
  quicknotes-data:
    name: quicknotes-data
```

```docker-compose up --build -d```

Creating network "devops-intro_default" with the default driver
Creating volume "quicknotes-data" with default driver
Building quicknotes
DEPRECATED: The legacy builder is deprecated and will be removed in a future release.
            Install the buildx component to build images with BuildKit:
            https://docs.docker.com/go/buildx/

Sending build context to Docker daemon  32.77kB
Step 1/11 : FROM golang:1.24-alpine AS builder
 ---> 8bee1901f1e5
Step 2/11 : WORKDIR /build
 ---> Using cache
 ---> 3a3900d69d95
Step 3/11 : COPY go.mod ./
 ---> Using cache
 ---> 89ec28a9a659
Step 4/11 : RUN go mod download
 ---> Using cache
 ---> 1c5deacc2eb0
Step 5/11 : COPY . .
 ---> Using cache
 ---> 0796c7fbd90e
Step 6/11 : RUN CGO_ENABLED=0 GOOS=linux go build     -ldflags='-s -w'     -trimpath     -o quicknotes .
 ---> Using cache
 ---> 48999180db7d
Step 7/11 : FROM gcr.io/distroless/static:nonroot
 ---> 963fa6c544fe
Step 8/11 : COPY --from=builder /build/quicknotes /quicknotes
 ---> Using cache
 ---> 4e06adfe897f
Step 9/11 : USER 65532:65532
 ---> Using cache
 ---> b637dbefae84
Step 10/11 : EXPOSE 8080
 ---> Using cache
 ---> 00cd23a3ba73
Step 11/11 : ENTRYPOINT ["/quicknotes"]
 ---> Using cache
 ---> 3e56b235cfc0
Successfully built 3e56b235cfc0
Successfully tagged quicknotes:lab6
Creating quicknotes ... done

```curl -X POST -H 'Content-Type: application/json' -d '{"title":"durable","body":"survive a restart"}' http://127.0.0.1:8080/notes```

```curl -s http://localhost:8080/notes | grep durable```

{"title":"durable","body":"survive a restart"}

```docker-compose down```

Stopping quicknotes ... done
Removing quicknotes ... done
Removing network devops-intro_default

```docker-compose up -d```do

Creating network "devops-intro_default" with the default driver
Creating quicknotes ... done


```docker-compose down -v```

Stopping quicknotes ... done
Removing quicknotes ... done
Removing network devops-intro_default
Removing volume quicknotes-data

```curl -s http://localhost:8080/notes | grep durable```
{}

<h2>Questions:</h2>

```e) Distroless has no shell. How do you healthcheck it? Pick a strategy; explain. (Options: HTTP via a separate sidecar; wget-only debug image; rely on Docker's default behavior of just checking the process is alive; use a binary that's already in the image.)```

Use the exec‑form of the healthcheck command: ```test: ["CMD", "/quicknotes", "-healthcheck"]```. and implement a -healthcheck flag in the QuickNotes binary that internally calls the /health endpoint and exits with 0 on success, 1 on failure

```f) Why does volumes: [quicknotes-data:/data] survive docker compose down? And what does destroy it?```

An named volume like <b>quicknotes-data</b> survives <b>docker-compose down</b> because <b>docker-compose down</b> does not delete named volumes by default – it only stops and removes containers, networks, and possibly images, but leaves volumes intact

```g) depends_on without condition: service_healthy — what does it actually wait for? What's the bug it can cause?```

Without <b>condition: service_healthy, depends_on</b> only waits for the dependent container to reach the <b>running</b> state (i.e., the process has started). It does not wait for the service to be fully initialized and ready to accept requests.
