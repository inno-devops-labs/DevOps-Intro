# lab 6 submission

# Lab 6 — Containers: Dockerize QuickNotes

Environment:

* Host System: Windows 10
* Docker Desktop: 29.5.3
* Docker Engine: 29.5.3
* Docker Compose: v5.1.4
---
## Task 1 — Multi-Stage Dockerfile

### 1.1 Requirements implementation

| Requirement              | Implementation                      |
| ------------------------ | ----------------------------------- |
| Multi-stage build        | Builder + Runtime stages            |
| Builder image            | `golang:1.24-alpine`                |
| Runtime image            | `gcr.io/distroless/static:nonroot`  |
| Static binary            | `CGO_ENABLED=0`                     |
| Binary optimization      | `-trimpath -ldflags="-s -w"`        |
| User                     | `nonroot`                           |
| Entrypoint               | `["/quicknotes"]`                   |
| Exposed port             | `8080`                              |
| Layer cache optimization | `go.mod` copied before source files |

### Dockerfile

```dockerfile
# Builder stage
FROM golang:1.24-alpine AS builder
WORKDIR /src
COPY go.mod ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /quicknotes

# Runtime stage
FROM gcr.io/distroless/static:nonroot
COPY --from=builder /quicknotes /quicknotes
COPY seed.json /seed.json
EXPOSE 8080
USER nonroot
ENTRYPOINT ["/quicknotes"]
```

### Build verification

Build command:
```powershell
PS C:\Users\P4IN\DevOps-Intro> docker build -t quicknotes:lab6 ./app
[+] Building 14.8s (16/16) FINISHED                                                        docker:desktop-linux
 => [internal] load build definition from Dockerfile                                                       0.1s
 => => transferring dockerfile: 426B                                                                       0.0s
 => [internal] load metadata for gcr.io/distroless/static:nonroot                                          2.7s

....

 => [builder 2/6] WORKDIR /src                                                                             0.4s
 => [builder 3/6] COPY go.mod ./                                                                           0.2s
 => [builder 4/6] RUN go mod download                                                                      0.4s
 => [builder 5/6] COPY . .                                                                                 0.1s
 => [builder 6/6] RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /quicknotes                     5.1s
 => [stage-1 2/3] COPY --from=builder /quicknotes /quicknotes                                              0.1s
 => [stage-1 3/3] COPY seed.json /seed.json                                                                0.1s
 => exporting to image                                                                                     0.8s
 => => exporting layers                                                                                    0.4s
 => => exporting manifest sha256:bd2499c355bcd04280f50ae85446ac3087dcbce7b3227be983341fcdc8c2f3e3          0.0s
 => => exporting config sha256:6c1303ea7d0b3b116fe8b78e1d2119811d43ac250d2c998d0f89970989f7f28e            0.0s
 => => exporting attestation manifest sha256:4c3ffdba9f443783d3631055bb2b764338174ffcb62ccbe590d5637abe80  0.1s
 => => exporting manifest list sha256:f0b0eb772d6cf0c6faec2e1fadcb3f7bd983d68e83cc4ea2738adae7f2321286     0.0s
 => => naming to docker.io/library/quicknotes:lab6                                                         0.0s
 => => unpacking to docker.io/library/quicknotes:lab6                                                      0.1s
```

Image size:
```powershell
PS C:\Users\P4IN\DevOps-Intro> docker images quicknotes:lab6
                                                                                            i Info →   U  In Use
IMAGE             ID             DISK USAGE   CONTENT SIZE   EXTRA
quicknotes:lab6   f0b0eb772d6c       14.8MB         3.32MB
```

Run container:
```powershell
PS C:\Users\P4IN\DevOps-Intro> docker run --rm -d `
>>   --name quicknotes-lab6 `
>>   -p 8080:8080 `
>>   quicknotes:lab6
7ff18310bb9b655b55d84aa9d80f2a86ad50cc4631b94b16e0a67b11a0484e1b
```

Health endpoint:
```powershell
PS C:\Users\P4IN\DevOps-Intro> curl http://localhost:8080/health
StatusCode        : 200
StatusDescription : OK
Content           : {"notes":0,"status":"ok"}
RawContent        : HTTP/1.1 200 OK
                    Content-Length: 26
                    Content-Type: application/json
                    Date: Tue, 23 Jun 2026 01:50:45 GMT
                    {"notes":0,"status":"ok"}
```

Notes endpoint:
```powershell
PS C:\Users\P4IN\DevOps-Intro> curl http://localhost:8080/notes
StatusCode        : 200
StatusDescription : OK
Content           : []
RawContent        : HTTP/1.1 200 OK
                    Content-Length: 3
                    Content-Type: application/json
                    Date: Tue, 23 Jun 2026 01:51:01 GMT
                    []
```

### Docker image inspection

User:
```powershell
PS C:\Users\P4IN\DevOps-Intro> docker inspect quicknotes:lab6 --format "{{.Config.User}}"
nonroot
```
Exposed Ports:
```powershell
PS C:\Users\P4IN\DevOps-Intro> docker inspect quicknotes:lab6 --format "{{json .Config.ExposedPorts}}"
{"8080/tcp":{}}
```
Entrypoint:
```powershell
PS C:\Users\P4IN\DevOps-Intro> docker inspect quicknotes:lab6 --format "{{json .Config.Entrypoint}}"
["/quicknotes"]
```

### 1.2 Design questions

#### a) Why does layer-order matter? Show before/after rebuild times for two strategies: COPY . . && go mod download && go build vs COPY go.mod go.sum ./ && go mod download && COPY . . && go build

Rebuild measurements:

Strategy 1:
```powershell
PS C:\Users\P4IN\DevOps-Intro> Measure-Command { >> docker build -f app/Dockerfile.bad -t quicknotes:bad ./app >> }
TotalSeconds : 9,1148215
```
```text
COPY . .
go mod download
go build
```

Strategy 2 (optimized):
```powershell
PS C:\Users\P4IN\DevOps-Intro> Measure-Command { >> docker build -t quicknotes:lab6 ./app >> }
TotalSeconds : 7,3836634
```
```text
COPY go.mod
go mod download
COPY . .
go build
```

Docker caches layers independently. By copying go.mod before the application source code,
dependency downloads can be reused between builds.

If COPY . . is executed first, any source code change invalidates all subsequent layers,
forcing dependencies to be downloaded again.

Separating dependency files from application source improves cache efficiency and reduces rebuild time.

#### b) Why CGO_ENABLED=0? What happens in distroless-static if you forget it?

CGO_ENABLED=0 produces a fully static binary.
Distroless static images do not contain dynamic linkers or system libraries.
If CGO_ENABLED=1 is used, the application may fail to start with an error similar to:

no such file or directory

because the required dynamic libraries are missing.

#### c) What is gcr.io/distroless/static:nonroot? What's in it, what isn't, and why does that matter for CVEs?

gcr.io/distroless/static:nonroot is a minimal runtime image maintained by Google.
It contains only the files required to run a statically compiled application.
It does not contain:
- a shell
- package managers
- compilers
- debugging utilities
The smaller attack surface significantly reduces the number of potential CVEs.

#### d) -ldflags='-s -w' and -trimpath: what does each flag do, and what's the cost?

-ldflags="-s -w"
removes symbol tables and debugging information from the binary, reducing its size.
-trimpath
removes local filesystem paths from the compiled binary, improving reproducibility.

The trade-off is that debugging becomes more difficult because debugging symbols and source paths are unavailable.


