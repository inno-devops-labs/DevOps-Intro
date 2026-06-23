# Lab 6 submission

## `dockerfile`:

```
FROM golang:1.24.5-alpine AS builder

WORKDIR /src

COPY go.mod ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 go build \
    -trimpath \
    -ldflags="-s -w" \
    -o /quicknotes

FROM gcr.io/distroless/static:nonroot

COPY --from=builder /quicknotes /quicknotes
COPY --from=builder /src/seed.json /seed.json

EXPOSE 8080

USER 65532:65532

ENTRYPOINT ["/quicknotes"]
```

### docker images quicknotes:lab6

```
docker images quicknotes:lab6
                                           i Info →   U  In Use
IMAGE          ID             DISK USAGE   CONTENT SIZE   EXTRA
quicknotes:lab6
               89c2136f5efc       14.7MB         3.32MB   
```

### docker inspect quicknotes:lab6 | jq '.[0].Config'

```
docker inspect quicknotes:lab6 | jq '.[0].Config'
{
  "Entrypoint": [
    "/quicknotes"
  ],
  "Env": [
    "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
    "SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt"
  ],
  "ExposedPorts": {
    "8080/tcp": {}
  },
  "User": "65532:65532",
  "WorkingDir": "/home/nonroot"
}
```

```
golang:1.24.5-alpine               daae04ebad0c        394MB         83.3MB        
```

## `compose.yalm`:

```
services:
  quicknotes:
    image: quicknotes:lab6
    build:
      context: ./app
    user: "0:0"

    ports:
      - "8080:8080"

    environment:
      ADDR: ":8080"
      DATA_PATH: "/data/notes.json"
      SEED_PATH: "/seed.json"

    volumes:
      - quicknotes-data:/data

    restart: unless-stopped

volumes:
  quicknotes-data:

```

```
long1tail@Long1Tail:~/DevOps-Intro $ docker compose up --build -d
sleep 3
curl -X POST -H 'Content-Type: application/json' \
  -d '{"title":"durable","body":"survive a restart"}' \
  http://localhost:8080/notes
curl -s http://localhost:8080/notes | grep durable            
WARN[0000] Docker Compose requires buildx plugin to be installed 
Sending build context to Docker daemon  5.188MB
Step 1/13 : FROM golang:1.24.5-alpine AS builder
 ---> daae04ebad0c
Step 2/13 : WORKDIR /src
 ---> Using cache
 ---> 799bad952f0f
Step 3/13 : COPY go.mod ./
 ---> Using cache
 ---> 7c1c40614b4e
Step 4/13 : RUN go mod download
 ---> Using cache
 ---> 822599abaeef
Step 5/13 : COPY . .
 ---> Using cache
 ---> 3540ad3ee96b
Step 6/13 : RUN CGO_ENABLED=0 go build     -trimpath     -ldflags="-s -w"     -o /quicknotes
 ---> Using cache
 ---> dff8776b7cc1
Step 7/13 : FROM gcr.io/distroless/static:nonroot
 ---> 963fa6c544fe
Step 8/13 : COPY --from=builder /quicknotes /quicknotes
 ---> Using cache
 ---> 1efb8b2954ad
Step 9/13 : COPY --from=builder /src/seed.json /seed.json
 ---> Using cache
 ---> 701937b2d2a6
Step 10/13 : EXPOSE 8080
 ---> Using cache
 ---> dfb1476938e2
Step 11/13 : USER 65532:65532
 ---> Using cache
 ---> 6715c8119c21
Step 12/13 : ENTRYPOINT ["/quicknotes"]
 ---> Using cache
 ---> 89c2136f5efc
Step 13/13 : LABEL com.docker.compose.image.builder=classic
 ---> Using cache
 ---> 57ea3a70d968
Successfully built 57ea3a70d968
Successfully tagged quicknotes:lab6
[+] up 2/2
 ✔ Image quicknotes:lab6               Built               0.4s
 ✔ Container devops-intro-quicknotes-1 Running             0.0s
{"id":5,"title":"durable","body":"survive a restart","created_at":"2026-06-23T19:29:07.590969929Z"}
[{"id":1,"title":"Welcome to QuickNotes","body":"This is the project you'll containerize, deploy, monitor, and harden across all 10 labs.","created_at":"2026-01-15T10:00:00Z"},{"id":2,"title":"Read app/main.go first","body":"Start by understanding the entry point — env vars, signal handling, graceful shutdown.","created_at":"2026-01-15T10:05:00Z"},{"id":3,"title":"DevOps mantra","body":"If it hurts, do it more often.","created_at":"2026-01-15T10:10:00Z"},{"id":4,"title":"Endpoint cheat-sheet","body":"GET /notes  GET /notes/{id}  POST /notes  DELETE /notes/{id}  GET /health  GET /metrics","created_at":"2026-01-15T10:15:00Z"},{"id":5,"title":"durable","body":"survive a restart","created_at":"2026-06-23T19:29:07.590969929Z"}]
long1tail@Long1Tail:~/DevOps-Intro $ docker compose down   
[+] down 2/2
 ✔ Container devops-intro-quicknotes-1 Removed             0.3s
 ✔ Network devops-intro_default        Removed             0.3s
long1tail@Long1Tail:~/DevOps-Intro $ docker compose up -d
sleep 3
curl -s http://localhost:8080/notes | grep durable
[+] up 2/2
 ✔ Network devops-intro_default        Created             0.1s
 ✔ Container devops-intro-quicknotes-1 Started             0.2s
[{"id":2,"title":"Read app/main.go first","body":"Start by understanding the entry point — env vars, signal handling, graceful shutdown.","created_at":"2026-01-15T10:05:00Z"},{"id":3,"title":"DevOps mantra","body":"If it hurts, do it more often.","created_at":"2026-01-15T10:10:00Z"},{"id":4,"title":"Endpoint cheat-sheet","body":"GET /notes  GET /notes/{id}  POST /notes  DELETE /notes/{id}  GET /health  GET /metrics","created_at":"2026-01-15T10:15:00Z"},{"id":5,"title":"durable","body":"survive a restart","created_at":"2026-06-23T19:29:07.590969929Z"},{"id":1,"title":"Welcome to QuickNotes","body":"This is the project you'll containerize, deploy, monitor, and harden across all 10 labs.","created_at":"2026-01-15T10:00:00Z"}]
long1tail@Long1Tail:~/DevOps-Intro $ docker compose down -v
[+] down 3/3
 ✔ Container devops-intro-quicknotes-1 Removed             0.3s
 ✔ Volume devops-intro_quicknotes-data Removed             0.0s
 ✔ Network devops-intro_default        Removed             0.3s
long1tail@Long1Tail:~/DevOps-Intro $ docker compose up -d
sleep 3
curl -s http://localhost:8080/notes | grep durable
[+] up 3/3
 ✔ Network devops-intro_default        Created             0.0s
 ✔ Volume devops-intro_quicknotes-data Created             0.0s
 ✔ Container devops-intro-quicknotes-1 Started             0.1s
 ```

 ### a

 Docker caches layers. If you COPY . . before go mod download, any source code change invalidates the cache and forces dependencies to be downloaded again. Copying only go.mod and go.sum first lets Docker reuse the dependency layer, so rebuilding after a code change is much faster.

 ### b

 CGO_ENABLED=0 produces a fully static Go binary. Distroless static images do not include system libraries like glibc, so a CGO-enabled binary may fail to start because required shared libraries are missing.

 ### c
 
 It's a minimal runtime image containing only essentials like CA certificates and a non-root user. It does not include a shell, package manager, or common Linux utilities. Fewer installed packages mean a smaller attack surface and fewer CVEs.

 ### d

 -s -w removes symbol and debug information, reducing binary size at the cost of harder debugging. -trimpath removes local filesystem paths from the binary, improving reproducibility and avoiding leakage of build-machine details.

 ### e

 The best approach is to use functionality built into the application binary itself, for example a /healthz endpoint or a dedicated healthcheck command. This avoids adding extra tools and works naturally with distroless images.


 ### f

 Because named volumes are managed separately from containers. docker compose down removes containers and networks, but keeps volumes. To delete the data, run docker compose down -v or remove the volume explicitly.

 ### g

 It only waits for the dependency container to start, not for the service inside it to become ready. This can cause race conditions where your app starts before the database is accepting connections and crashes on startup.