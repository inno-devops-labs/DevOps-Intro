# Lab 6
## Task 1

### Dockerfile
```Dockerfile
FROM golang:1.24 AS builder
WORKDIR /src

COPY go.mod go.sum* ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 go build -trimpath -ldflags='-s -w' -o /out/quicknotes .

RUN mkdir -p /data && chown 65532:65532 /data

RUN mkdir -p /hc && \
    printf 'package main\nimport ("net/http"; "os")\nfunc main() {\n  r, err := http.Get("http://localhost:8080/health")\n  if err != nil || r.StatusCode != 200 {\n    os.Exit(1)\n  }\n}\n' > /hc/main.go && \
    cd /hc && go mod init hc && \
    CGO_ENABLED=0 go build -trimpath -ldflags='-s -w' -o /out/healthcheck .

FROM gcr.io/distroless/static:nonroot
COPY --from=builder /out/quicknotes /quicknotes
COPY --from=builder /out/healthcheck /healthcheck
COPY seed.json /seed.json
COPY --chown=nonroot:nonroot --from=builder /data /data
EXPOSE 8080
USER nonroot
ENTRYPOINT ["/quicknotes"]
```

### golang:1.24 and custom container size comparison
```
thebruh@thebruh-PC MINGW64 ~/Desktop/DevOpsCourse/DevOps-Intro (feature/lab6)
$ docker images quicknotes:lab6
                                                                                                                                 i Info →   U  In Use
IMAGE             ID             DISK USAGE   CONTENT SIZE   EXTRA
quicknotes:lab6   5d649f79547f         23MB         5.76MB    U
```

```
thebruh@thebruh-PC MINGW64 ~/Desktop/DevOpsCourse/DevOps-Intro (feature/lab6)
$ docker images golang:1.24
                                                                                                                                 i Info →   U  In Use
IMAGE         ID             DISK USAGE   CONTENT SIZE   EXTRA
golang:1.24   d2d2bc1c84f7       1.32GB          335MB
```

### Build and verification
```
thebruh@thebruh-PC MINGW64 ~/Desktop/DevOpsCourse/DevOps-Intro/app (feature/lab6)
$ MSYS_NO_PATHCONV=1 docker run --rm -d --name qn6 -p 8080:8080 -v "C:/Users/thebruh/Desktop/DevOpsCourse/DevOps-Intro/app/data:/data" -e DATA_PATH=/data/notes.json -e SEED_PATH=/seed.json quicknotes:lab6
1e42d5e17a6869175213281ec5f092fca58c39005770273db5c8f6996d42069b

thebruh@thebruh-PC MINGW64 ~/Desktop/DevOpsCourse/DevOps-Intro/app (feature/lab6)
$ sleep 2

thebruh@thebruh-PC MINGW64 ~/Desktop/DevOpsCourse/DevOps-Intro/app (feature/lab6)
$ curl -s http://localhost:8080/health
{"notes":7,"status":"ok"}

thebruh@thebruh-PC MINGW64 ~/Desktop/DevOpsCourse/DevOps-Intro/app (feature/lab6)
$ docker inspect quicknotes:lab6 --format '{{ .Config.User }} {{ .Config.Entrypoint }} {{ .Config.ExposedPorts }}'
nonroot [/quicknotes] map[8080/tcp:{}]

thebruh@thebruh-PC MINGW64 ~/Desktop/DevOpsCourse/DevOps-Intro/app (feature/lab6)
$ docker rm -f qn6
qn6
```

### Questions

#### a) Why does layer-order matter?
I tested two builds:
1) Wrong order (`COPY . .` -> `go mod download` -> `go build`):
```
#9 [builder 3/7] COPY . .
#9 DONE 0.1s

#10 [builder 4/7] RUN go mod download
#10 0.384 go: no module dependencies to download
#10 DONE 0.4s

#11 [builder 5/7] RUN CGO_ENABLED=0 go build -trimpath -ldflags='-s -w' -o /out/quicknotes .
#11 DONE 7.9s
```

2) Correct order (`COPY go.mod go.sum`-> `go mod download` -> `COPY . .` -> `go build`):
```
#9 [builder 3/8] COPY go.mod go.sum* ./
#9 CACHED

#10 [builder 4/8] RUN go mod download
#10 CACHED

#11 [builder 5/8] COPY . .
#11 DONE 0.1s

#12 [builder 6/8] RUN CGO_ENABLED=0 go build -trimpath -ldflags='-s -w' -o /out/quicknotes .
#12 DONE 7.9s
```
Correct order caches the dependencies and does not rebuild them when source changes. In the wrong order, change in any file results in ```go mod download``` running again.

#### b) Why CGO_ENABLED=0? What happens in distroless-static if you forget it?
It disables CGO and makes Go binary which is statically linked. Without it, the app may not launch on distroless-static, since it doesnt have libraries for dynamically linked binaries.
#### c) What is gcr.io/distroless/static:nonroot? What's in it, what isn't, and why does that matter for CVEs?
It's a container that has only required files to run the app. It doesn't have shell, OS utilities and other unnecessary files. It's being launched as a non-root user. It greatly reduces the amount of components, which reduces possible backdoors and vulnerabilities inside the components.
#### d) -ldflags='-s -w' and -trimpath: what does each flag do, and what's the cost?
```-s``` removes symbol table from the binary.
```-w``` disables DWARF
```-trimpath``` removes local file paths.
The cost is that you intentionally reduce the debugging possibilities when using ```-s, -w```. ```-trimpath``` comes with a price of removing local path info. Of course, all of that is not really necessary if you don't need it.

## Task 2

### compose.yaml
This compose file already has security measures.
```yaml
services:
  quicknotes:
    build: ./app
    image: quicknotes:lab6
    ports:
      - "8080:8080"
    environment:
      ADDR: ":8080"
      DATA_PATH: /data/notes.json
      SEED_PATH: /seed.json
    volumes:
      - quicknotes-data:/data
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "/healthcheck"]
      interval: 10s
      timeout: 3s
      retries: 3
      start_period: 5s
    cap_drop:
      - ALL
    read_only: true
    tmpfs:
      - /tmp
    security_opt:
      - no-new-privileges:true

volumes:
  quicknotes-data:
```

### Persistence test
```
thebruh@thebruh-PC MINGW64 ~/Desktop/DevOpsCourse/DevOps-Intro (feature/lab6)
$ curl -X POST -H 'Content-Type: application/json' -d '{"title":"durable","body":"survive a restart"}' http://localhost:8080/notes
{"id":5,"title":"durable","body":"survive a restart","created_at":"2026-09-24T15:36:50.377082591Z"}

thebruh@thebruh-PC MINGW64 ~/Desktop/DevOpsCourse/DevOps-Intro (feature/lab6)
$ curl -s http://localhost:8080/notes | grep durable
[{"id":4,"title":"Endpoint cheat-sheet","body":"GET /notes  GET /notes/{id}  POST /notes  DELETE /notes/{id}  GET /health  GET /metrics","created_at":"2026-01-15T10:15:00Z"},{"id":5,"title":"durable","body":"survive a restart","created_at":"2026-09-24T15:36:50.377082591Z"},{"id":1,"title":"Welcome to QuickNotes","body":"This is the project you'll containerize, deploy, monitor, and harden across all 10 labs.","created_at":"2026-01-15T10:00:00Z"},{"id":2,"title":"Read app/main.go first","body":"Start by understanding the entry point — env vars, signal handling, graceful shutdown.","created_at":"2026-01-15T10:05:00Z"},{"id":3,"title":"DevOps mantra","body":"If it hurts, do it more often.","created_at":"2026-01-15T10:10:00Z"}]

thebruh@thebruh-PC MINGW64 ~/Desktop/DevOpsCourse/DevOps-Intro (feature/lab6)
$ docker compose down
[+] down 2/2
 ✔ Container devops-intro-quicknotes-1 Removed                                                                                                   0.3s
 ✔ Network devops-intro_default        Removed                                                                                                   0.3s

thebruh@thebruh-PC MINGW64 ~/Desktop/DevOpsCourse/DevOps-Intro (feature/lab6)
$ docker compose up -d
[+] up 2/2
 ✔ Network devops-intro_default        Created                                                                                                   0.0s
 ✔ Container devops-intro-quicknotes-1 Started                                                                                                   0.2s

thebruh@thebruh-PC MINGW64 ~/Desktop/DevOpsCourse/DevOps-Intro (feature/lab6)
$ sleep 5

thebruh@thebruh-PC MINGW64 ~/Desktop/DevOpsCourse/DevOps-Intro (feature/lab6)
$ curl -s http://localhost:8080/notes | grep durable
[{"id":4,"title":"Endpoint cheat-sheet","body":"GET /notes  GET /notes/{id}  POST /notes  DELETE /notes/{id}  GET /health  GET /metrics","created_at":"2026-01-15T10:15:00Z"},{"id":5,"title":"durable","body":"survive a restart","created_at":"2026-09-24T15:36:50.377082591Z"},{"id":1,"title":"Welcome to QuickNotes","body":"This is the project you'll containerize, deploy, monitor, and harden across all 10 labs.","created_at":"2026-01-15T10:00:00Z"},{"id":2,"title":"Read app/main.go first","body":"Start by understanding the entry point — env vars, signal handling, graceful shutdown.","created_at":"2026-01-15T10:05:00Z"},{"id":3,"title":"DevOps mantra","body":"If it hurts, do it more often.","created_at":"2026-01-15T10:10:00Z"}]

thebruh@thebruh-PC MINGW64 ~/Desktop/DevOpsCourse/DevOps-Intro (feature/lab6)
$ docker compose down -v
[+] down 3/3
 ✔ Container devops-intro-quicknotes-1 Removed                                                                                                   0.3s
 ✔ Volume devops-intro_quicknotes-data Removed                                                                                                   0.0s
 ✔ Network devops-intro_default        Removed                                                                                                   0.2s

thebruh@thebruh-PC MINGW64 ~/Desktop/DevOpsCourse/DevOps-Intro (feature/lab6)
$ docker compose up -d
[+] up 3/3
 ✔ Network devops-intro_default        Created                                                                                                   0.0s
 ✔ Volume devops-intro_quicknotes-data Created                                                                                                   0.0s
 ✔ Container devops-intro-quicknotes-1 Started                                                                                                   0.2s

thebruh@thebruh-PC MINGW64 ~/Desktop/DevOpsCourse/DevOps-Intro (feature/lab6)
$ sleep 5

thebruh@thebruh-PC MINGW64 ~/Desktop/DevOpsCourse/DevOps-Intro (feature/lab6)
$ curl -s http://localhost:8080/notes | grep durable

thebruh@thebruh-PC MINGW64 ~/Desktop/DevOpsCourse/DevOps-Intro (feature/lab6)
$
```

### Questions
#### e) Distroless has no shell. How do you healthcheck it?
I pre compiled a binary dedicated for healthcheck during build stage. it returns 0 if everything is alright, and 1 in case of failure. It runs directly without needing a shell.
#### f) Why does volumes: [quicknotes-data:/data] survive docker compose down? And what does destroy it?
Since ```quicknotes-data``` is a named volume, it is kept after ```docker compose down```. \
To destroy it, flag ```-v``` must be used:
```docker compose down -v``` \
Also, it can be removed explicitly:
```docker volume rm quicknotes-data```
#### g) depends_on without condition: service_healthy — what does it actually wait for? What's the bug it can cause?
without service_healthy, depends_on waits until the dependency container has started. But it doesnt check whether it is ready or not. That may result in dependent service trying to interact with the service that is not ready, which will probably result in errors and fail the whole app.

## Bonus task
```compose.yaml``` was improved, and can be seen in ```Task 2``` section.
### Security verification
```
thebruh@thebruh-PC MINGW64 ~/Desktop/DevOpsCourse/DevOps-Intro (feature/lab6)
$ docker inspect quicknotes:lab6 --format '{{ .Config.User }}'
nonroot

thebruh@thebruh-PC MINGW64 ~/Desktop/DevOpsCourse/DevOps-Intro (feature/lab6)
$ docker compose exec quicknotes sh
OCI runtime exec failed: exec failed: unable to start container process: exec: "sh": executable file not found in $PATH

What's next:
    Debug this Compose error with Gordon → docker ai "help me fix this compose error"

thebruh@thebruh-PC MINGW64 ~/Desktop/DevOpsCourse/DevOps-Intro (feature/lab6)
$ docker compose ps -q quicknotes
fc2d75ddf0a59acee2d4ba54f79d1a42e0a2e0e0859cb7da74002e4ea07c21a8

thebruh@thebruh-PC MINGW64 ~/Desktop/DevOpsCourse/DevOps-Intro (feature/lab6)
$ docker inspect fc2d75ddf0a59acee2d4ba54f79d1a42e0a2e0e0859cb7da74002e4ea07c21a8 --format '{{ .HostConfig.CapDrop }}'
[ALL]

thebruh@thebruh-PC MINGW64 ~/Desktop/DevOpsCourse/DevOps-Intro (feature/lab6)
$ docker inspect  fc2d75ddf0a59acee2d4ba54f79d1a42e0a2e0e0859cb7da74002e4ea07c21a8 --format '{{ .HostConfig.ReadonlyRootfs }} {{ .HostConfig.SecurityOpt }}'
true [no-new-privileges:true]
```

### Trivy run
```
thebruh@thebruh-PC MINGW64 ~/Desktop/DevOpsCourse/DevOps-Intro (feature/lab6)
$ MSYS_NO_PATHCONV=1 docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:0.59.1 image --severity HIGH,CRITICAL --no-progress quicknotes:lab6
Unable to find image 'aquasec/trivy:0.59.1' locally
0.59.1: Pulling from aquasec/trivy
2167091a7879: Pull complete
38a8310d387e: Pull complete
2c38dcf52ab2: Pull complete
1d671f98de6b: Pull complete
Digest: sha256:029e990b328d149bf0a9ffe355919041e1f86192db2df47e217f8a36dd42ceac
Status: Downloaded newer image for aquasec/trivy:0.59.1
2026-09-24T15:41:58Z    INFO    [vulndb] Need to update DB
2026-09-24T15:41:58Z    INFO    [vulndb] Downloading vulnerability DB...
2026-09-24T15:41:58Z    INFO    [vulndb] Downloading artifact...        repo="mirror.gcr.io/aquasec/trivy-db:2"
2026-09-24T15:42:21Z    INFO    [vulndb] Artifact successfully downloaded       repo="mirror.gcr.io/aquasec/trivy-db:2"
2026-09-24T15:42:21Z    INFO    [vuln] Vulnerability scanning is enabled
2026-09-24T15:42:21Z    INFO    [secret] Secret scanning is enabled
2026-09-24T15:42:21Z    INFO    [secret] If your scanning is slow, please try '--scanners vuln' to disable secret scanning
2026-09-24T15:42:21Z    INFO    [secret] Please see also https://aquasecurity.github.io/trivy/v0.59/docs/scanner/secret#recommendation for faster secret detection
2026-09-24T15:42:21Z    INFO    Detected OS     family="debian" version="13.7"
2026-09-24T15:42:21Z    INFO    [debian] Detecting vulnerabilities...   os_version="13" pkg_num=6
2026-09-24T15:42:21Z    INFO    Number of language-specific files       num=2
2026-09-24T15:42:21Z    INFO    [gobinary] Detecting vulnerabilities...
2026-09-24T15:42:21Z    WARN    Using severities from other vendors for some vulnerabilities. Read https://aquasecurity.github.io/trivy/v0.59/docs/scanner/vulnerability#severity-selection for details.

quicknotes:lab6 (debian 13.7)
=============================
Total: 0 (HIGH: 0, CRITICAL: 0)


healthcheck (gobinary)
======================
Total: 19 (HIGH: 19, CRITICAL: 0)

┌─────────┬────────────────┬──────────┬────────┬───────────────────┬──────────────────────────────┬──────────────────────────────────────────────────────────────┐
│ Library │ Vulnerability  │ Severity │ Status │ Installed Version │        Fixed Version         │                            Title
            │
├─────────┼────────────────┼──────────┼────────┼───────────────────┼──────────────────────────────┼──────────────────────────────────────────────────────────────┤
│ stdlib  │ CVE-2026-25679 │ HIGH     │ fixed  │ v1.24.13          │ 1.25.8, 1.26.1               │ net/url: Incorrect parsing of IPv6 host literals in net/url  │
│         │                │          │        │                   │                              │ https://avd.aquasec.com/nvd/cve-2026-25679                   │
│         ├────────────────┤          │        │                   ├──────────────────────────────┼──────────────────────────────────────────────────────────────┤
│         │ CVE-2026-27145 │          │        │                   │ 1.25.11, 1.26.4              │ crypto/x509: golang: golang crypto/x509: Denial of Service   │
│         │                │          │        │                   │                              │ via excessive processing of DNS...
            │
│         │                │          │        │                   │                              │ https://avd.aquasec.com/nvd/cve-2026-27145                   │
│         ├────────────────┤          │        │                   ├──────────────────────────────┼──────────────────────────────────────────────────────────────┤
│         │ CVE-2026-32280 │          │        │                   │ 1.25.9, 1.26.2               │ crypto/x509: crypto/tls: golang: Go: Denial of Service       │
│         │                │          │        │                   │                              │ vulnerability in certificate chain building...               │
│         │                │          │        │                   │                              │ https://avd.aquasec.com/nvd/cve-2026-32280                   │
│         ├────────────────┤          │        │                   │                              ├──────────────────────────────────────────────────────────────┤
│         │ CVE-2026-32281 │          │        │                   │                              │ crypto/x509: golang: Go crypto/x509: Denial of Service via   │
│         │                │          │        │                   │                              │ inefficient certificate chain validation...                  │
│         │                │          │        │                   │                              │ https://avd.aquasec.com/nvd/cve-2026-32281                   │
│         ├────────────────┤          │        │                   │                              ├──────────────────────────────────────────────────────────────┤
│         │ CVE-2026-32283 │          │        │                   │                              │ crypto/tls: golang: Go crypto/tls: Denial of Service via     │
│         │                │          │        │                   │                              │ multiple TLS 1.3 key...
            │
│         │                │          │        │                   │                              │ https://avd.aquasec.com/nvd/cve-2026-32283                   │
│         ├────────────────┤          │        │                   ├──────────────────────────────┼──────────────────────────────────────────────────────────────┤
│         │ CVE-2026-33811 │          │        │                   │ 1.25.10, 1.26.3              │ net: golang: Go net package: Denial of Service via long      │
│         │                │          │        │                   │                              │ CNAME response...
            │
│         │                │          │        │                   │                              │ https://avd.aquasec.com/nvd/cve-2026-33811                   │
│         ├────────────────┤          │        │                   │                              ├──────────────────────────────────────────────────────────────┤
│         │ CVE-2026-33814 │          │        │                   │                              │ net/http/internal/http2: golang: golang.org/x/net: Go        │
│         │                │          │        │                   │                              │ HTTP/2: Denial of Service via malformed
            │
│         │                │          │        │                   │                              │ SETTINGS_MAX_FRAME_SIZE frame...
            │
│         │                │          │        │                   │                              │ https://avd.aquasec.com/nvd/cve-2026-33814                   │
│         ├────────────────┤          │        │                   ├──────────────────────────────┼──────────────────────────────────────────────────────────────┤
│         │ CVE-2026-33818 │          │        │                   │ 1.25.13, 1.26.6, 1.27.0-rc.3 │ encoding/asn1: golang: Go encoding/asn1: Denial of Service   │
│         │                │          │        │                   │                              │ via excessive recursion in Unmarshal...
            │
│         │                │          │        │                   │                              │ https://avd.aquasec.com/nvd/cve-2026-33818                   │
│         ├────────────────┤          │        │                   ├──────────────────────────────┼──────────────────────────────────────────────────────────────┤
│         │ CVE-2026-39820 │          │        │                   │ 1.25.10, 1.26.3              │ net/mail: golang: Go net/mail: Denial of Service via crafted │
│         │                │          │        │                   │                              │ email inputs
            │
│         │                │          │        │                   │                              │ https://avd.aquasec.com/nvd/cve-2026-39820                   │
│         ├────────────────┤          │        │                   ├──────────────────────────────┼──────────────────────────────────────────────────────────────┤
│         │ CVE-2026-39821 │          │        │                   │ 1.25.13, 1.26.6, 1.27.0-rc.3 │ golang.org/x/net/idna: golang: net/http:
            │
│         │                │          │        │                   │                              │ golang.org/x/net/idna: Privilege escalation via incorrect    │
│         │                │          │        │                   │                              │ Punycode label processing
            │
│         │                │          │        │                   │                              │ https://avd.aquasec.com/nvd/cve-2026-39821                   │
│         ├────────────────┤          │        │                   ├──────────────────────────────┼──────────────────────────────────────────────────────────────┤
│         │ CVE-2026-39822 │          │        │                   │ 1.25.12, 1.26.5, 1.27.0-rc.2 │ golang: Go os.Root: Symlink following vulnerability allows   │
│         │                │          │        │                   │                              │ directory traversal
            │
│         │                │          │        │                   │                              │ https://avd.aquasec.com/nvd/cve-2026-39822                   │
│         ├────────────────┤          │        │                   ├──────────────────────────────┼──────────────────────────────────────────────────────────────┤
│         │ CVE-2026-39836 │          │        │                   │ 1.25.10, 1.26.3              │ net: golang: Go net package: Denial of Service via NUL byte  │
│         │                │          │        │                   │                              │ in...
            │
│         │                │          │        │                   │                              │ https://avd.aquasec.com/nvd/cve-2026-39836                   │
│         ├────────────────┤          │        │                   │                              ├──────────────────────────────────────────────────────────────┤
│         │ CVE-2026-42499 │          │        │                   │                              │ net/mail: golang: net/mail: Denial of Service via            │
│         │                │          │        │                   │                              │ pathological email address parsing
            │
│         │                │          │        │                   │                              │ https://avd.aquasec.com/nvd/cve-2026-42499                   │
│         ├────────────────┤          │        │                   ├──────────────────────────────┼──────────────────────────────────────────────────────────────┤
│         │ CVE-2026-42504 │          │        │                   │ 1.25.11, 1.26.4              │ mime: golang: Golang MIME: Denial of Service via             │
│         │                │          │        │                   │                              │ maliciously-crafted MIME header
            │
│         │                │          │        │                   │                              │ https://avd.aquasec.com/nvd/cve-2026-42504                   │
│         ├────────────────┤          │        │                   ├──────────────────────────────┼──────────────────────────────────────────────────────────────┤
│         │ CVE-2026-56853 │          │        │                   │ 1.25.13, 1.26.6, 1.27.0-rc.3 │ net/http: golang: Go net/http: Unencrypted HTTP/2            │
│         │                │          │        │                   │                              │ connections vulnerable to Denial of Service...               │
│         │                │          │        │                   │                              │ https://avd.aquasec.com/nvd/cve-2026-56853                   │
│         ├────────────────┤          │        │                   │                              ├──────────────────────────────────────────────────────────────┤
│         │ CVE-2026-56858 │          │        │                   │                              │ html/template: golang: Go html/template: Cross-Site          │
│         │                │          │        │                   │                              │ Scripting via pathological input
            │
│         │                │          │        │                   │                              │ https://avd.aquasec.com/nvd/cve-2026-56858                   │
│         ├────────────────┤          │        │                   │                              ├──────────────────────────────────────────────────────────────┤
│         │ CVE-2026-56859 │          │        │                   │                              │ encoding/xml: golang: Go: Denial of Service via XML decoding │
│         │                │          │        │                   │                              │ recursion depth issue...
            │
│         │                │          │        │                   │                              │ https://avd.aquasec.com/nvd/cve-2026-56859                   │
│         ├────────────────┤          │        │                   │                              ├──────────────────────────────────────────────────────────────┤
│         │ CVE-2026-56860 │          │        │                   │                              │ net/url: golang: golang net/url: Denial of Service from      │
│         │                │          │        │                   │                              │ quadratic complexity in path...
            │
│         │                │          │        │                   │                              │ https://avd.aquasec.com/nvd/cve-2026-56860                   │
│         ├────────────────┤          │        │                   │                              ├──────────────────────────────────────────────────────────────┤
│         │ CVE-2026-56862 │          │        │                   │                              │ crypto/tls: golang: Golang crypto/tls: Denial of Service via │
│         │                │          │        │                   │                              │ indefinite KeyUpdate messages
            │
│         │                │          │        │                   │                              │ https://avd.aquasec.com/nvd/cve-2026-56862                   │
└─────────┴────────────────┴──────────┴────────┴───────────────────┴──────────────────────────────┴──────────────────────────────────────────────────────────────┘

quicknotes (gobinary)
=====================
Total: 19 (HIGH: 19, CRITICAL: 0)

┌─────────┬────────────────┬──────────┬────────┬───────────────────┬──────────────────────────────┬──────────────────────────────────────────────────────────────┐
│ Library │ Vulnerability  │ Severity │ Status │ Installed Version │        Fixed Version         │                            Title
            │
├─────────┼────────────────┼──────────┼────────┼───────────────────┼──────────────────────────────┼──────────────────────────────────────────────────────────────┤
│ stdlib  │ CVE-2026-25679 │ HIGH     │ fixed  │ v1.24.13          │ 1.25.8, 1.26.1               │ net/url: Incorrect parsing of IPv6 host literals in net/url  │
│         │                │          │        │                   │                              │ https://avd.aquasec.com/nvd/cve-2026-25679                   │
│         ├────────────────┤          │        │                   ├──────────────────────────────┼──────────────────────────────────────────────────────────────┤
│         │ CVE-2026-27145 │          │        │                   │ 1.25.11, 1.26.4              │ crypto/x509: golang: golang crypto/x509: Denial of Service   │
│         │                │          │        │                   │                              │ via excessive processing of DNS...
            │
│         │                │          │        │                   │                              │ https://avd.aquasec.com/nvd/cve-2026-27145                   │
│         ├────────────────┤          │        │                   ├──────────────────────────────┼──────────────────────────────────────────────────────────────┤
│         │ CVE-2026-32280 │          │        │                   │ 1.25.9, 1.26.2               │ crypto/x509: crypto/tls: golang: Go: Denial of Service       │
│         │                │          │        │                   │                              │ vulnerability in certificate chain building...               │
│         │                │          │        │                   │                              │ https://avd.aquasec.com/nvd/cve-2026-32280                   │
│         ├────────────────┤          │        │                   │                              ├──────────────────────────────────────────────────────────────┤
│         │ CVE-2026-32281 │          │        │                   │                              │ crypto/x509: golang: Go crypto/x509: Denial of Service via   │
│         │                │          │        │                   │                              │ inefficient certificate chain validation...                  │
│         │                │          │        │                   │                              │ https://avd.aquasec.com/nvd/cve-2026-32281                   │
│         ├────────────────┤          │        │                   │                              ├──────────────────────────────────────────────────────────────┤
│         │ CVE-2026-32283 │          │        │                   │                              │ crypto/tls: golang: Go crypto/tls: Denial of Service via     │
│         │                │          │        │                   │                              │ multiple TLS 1.3 key...
            │
│         │                │          │        │                   │                              │ https://avd.aquasec.com/nvd/cve-2026-32283                   │
│         ├────────────────┤          │        │                   ├──────────────────────────────┼──────────────────────────────────────────────────────────────┤
│         │ CVE-2026-33811 │          │        │                   │ 1.25.10, 1.26.3              │ net: golang: Go net package: Denial of Service via long      │
│         │                │          │        │                   │                              │ CNAME response...
            │
│         │                │          │        │                   │                              │ https://avd.aquasec.com/nvd/cve-2026-33811                   │
│         ├────────────────┤          │        │                   │                              ├──────────────────────────────────────────────────────────────┤
│         │ CVE-2026-33814 │          │        │                   │                              │ net/http/internal/http2: golang: golang.org/x/net: Go        │
│         │                │          │        │                   │                              │ HTTP/2: Denial of Service via malformed
            │
│         │                │          │        │                   │                              │ SETTINGS_MAX_FRAME_SIZE frame...
            │
│         │                │          │        │                   │                              │ https://avd.aquasec.com/nvd/cve-2026-33814                   │
│         ├────────────────┤          │        │                   ├──────────────────────────────┼──────────────────────────────────────────────────────────────┤
│         │ CVE-2026-33818 │          │        │                   │ 1.25.13, 1.26.6, 1.27.0-rc.3 │ encoding/asn1: golang: Go encoding/asn1: Denial of Service   │
│         │                │          │        │                   │                              │ via excessive recursion in Unmarshal...
            │
│         │                │          │        │                   │                              │ https://avd.aquasec.com/nvd/cve-2026-33818                   │
│         ├────────────────┤          │        │                   ├──────────────────────────────┼──────────────────────────────────────────────────────────────┤
│         │ CVE-2026-39820 │          │        │                   │ 1.25.10, 1.26.3              │ net/mail: golang: Go net/mail: Denial of Service via crafted │
│         │                │          │        │                   │                              │ email inputs
            │
│         │                │          │        │                   │                              │ https://avd.aquasec.com/nvd/cve-2026-39820                   │
│         ├────────────────┤          │        │                   ├──────────────────────────────┼──────────────────────────────────────────────────────────────┤
│         │ CVE-2026-39821 │          │        │                   │ 1.25.13, 1.26.6, 1.27.0-rc.3 │ golang.org/x/net/idna: golang: net/http:
            │
│         │                │          │        │                   │                              │ golang.org/x/net/idna: Privilege escalation via incorrect    │
│         │                │          │        │                   │                              │ Punycode label processing
            │
│         │                │          │        │                   │                              │ https://avd.aquasec.com/nvd/cve-2026-39821                   │
│         ├────────────────┤          │        │                   ├──────────────────────────────┼──────────────────────────────────────────────────────────────┤
│         │ CVE-2026-39822 │          │        │                   │ 1.25.12, 1.26.5, 1.27.0-rc.2 │ golang: Go os.Root: Symlink following vulnerability allows   │
│         │                │          │        │                   │                              │ directory traversal
            │
│         │                │          │        │                   │                              │ https://avd.aquasec.com/nvd/cve-2026-39822                   │
│         ├────────────────┤          │        │                   ├──────────────────────────────┼──────────────────────────────────────────────────────────────┤
│         │ CVE-2026-39836 │          │        │                   │ 1.25.10, 1.26.3              │ net: golang: Go net package: Denial of Service via NUL byte  │
│         │                │          │        │                   │                              │ in...
            │
│         │                │          │        │                   │                              │ https://avd.aquasec.com/nvd/cve-2026-39836                   │
│         ├────────────────┤          │        │                   │                              ├──────────────────────────────────────────────────────────────┤
│         │ CVE-2026-42499 │          │        │                   │                              │ net/mail: golang: net/mail: Denial of Service via            │
│         │                │          │        │                   │                              │ pathological email address parsing
            │
│         │                │          │        │                   │                              │ https://avd.aquasec.com/nvd/cve-2026-42499                   │
│         ├────────────────┤          │        │                   ├──────────────────────────────┼──────────────────────────────────────────────────────────────┤
│         │ CVE-2026-42504 │          │        │                   │ 1.25.11, 1.26.4              │ mime: golang: Golang MIME: Denial of Service via             │
│         │                │          │        │                   │                              │ maliciously-crafted MIME header
            │
│         │                │          │        │                   │                              │ https://avd.aquasec.com/nvd/cve-2026-42504                   │
│         ├────────────────┤          │        │                   ├──────────────────────────────┼──────────────────────────────────────────────────────────────┤
│         │ CVE-2026-56853 │          │        │                   │ 1.25.13, 1.26.6, 1.27.0-rc.3 │ net/http: golang: Go net/http: Unencrypted HTTP/2            │
│         │                │          │        │                   │                              │ connections vulnerable to Denial of Service...               │
│         │                │          │        │                   │                              │ https://avd.aquasec.com/nvd/cve-2026-56853                   │
│         ├────────────────┤          │        │                   │                              ├──────────────────────────────────────────────────────────────┤
│         │ CVE-2026-56858 │          │        │                   │                              │ html/template: golang: Go html/template: Cross-Site          │
│         │                │          │        │                   │                              │ Scripting via pathological input
            │
│         │                │          │        │                   │                              │ https://avd.aquasec.com/nvd/cve-2026-56858                   │
│         ├────────────────┤          │        │                   │                              ├──────────────────────────────────────────────────────────────┤
│         │ CVE-2026-56859 │          │        │                   │                              │ encoding/xml: golang: Go: Denial of Service via XML decoding │
│         │                │          │        │                   │                              │ recursion depth issue...
            │
│         │                │          │        │                   │                              │ https://avd.aquasec.com/nvd/cve-2026-56859                   │
│         ├────────────────┤          │        │                   │                              ├──────────────────────────────────────────────────────────────┤
│         │ CVE-2026-56860 │          │        │                   │                              │ net/url: golang: golang net/url: Denial of Service from      │
│         │                │          │        │                   │                              │ quadratic complexity in path...
            │
│         │                │          │        │                   │                              │ https://avd.aquasec.com/nvd/cve-2026-56860                   │
│         ├────────────────┤          │        │                   │                              ├──────────────────────────────────────────────────────────────┤
│         │ CVE-2026-56862 │          │        │                   │                              │ crypto/tls: golang: Golang crypto/tls: Denial of Service via │
│         │                │          │        │                   │                              │ indefinite KeyUpdate messages
            │
│         │                │          │        │                   │                              │ https://avd.aquasec.com/nvd/cve-2026-56862                   │
└─────────┴────────────────┴──────────┴────────┴───────────────────┴──────────────────────────────┴──────────────────────────────────────────────────────────────┘
```

### Trivy Summary
Trivy returned 0 HIGH and CRITICAL vulnerabilities in ```debian 13.7```. But 19 HIGH vulnerabilities in ```gobinary``` ```healthcheck``` binary, and 19 HIGH vulnerabilities in ```gobinary``` ```quicknotes``` binary. Lab requires go ```1.24```, so i can't do anything with it. But updating to ```1.25.x+``` will fix all of them.

### Which of the 6 defaults give the most security per line of YAML?
The most of the security comes from using distroless image and taking away the root rights. In pair with dropping all capabilities and making filesystem read-only, it reduces most of the dangers already. no-new-privileges also helps a bit, by preventing gaining privileges, but it plays less significant role in security.