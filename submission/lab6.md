# Lab 6 submission
### Dockerfile
[Link](../app/Dockerfile)

### Docker image
```sh
$ docker images quicknotes:lab6
IMAGE             ID             DISK USAGE   CONTENT SIZE   EXTRA
quicknotes:lab6   8a2f6d6991e6       5.93MB             0B    U   
```

### Image internals
```sh
$ docker inspect quicknotes:lab6 | jq '.[0].Config'
{
  "User": "nonroot",
  "ExposedPorts": {
    "8080/tcp": {}
  },
  "Env": [
    "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
  ],
  "Entrypoint": [
    "/app/qn-bin"
  ],
  "WorkingDir": "/app"
}
```

### Comparison with `golang:1.24.5` image
```sh
$ docker images golang:1.24.5
IMAGE           ID             DISK USAGE   CONTENT SIZE   EXTRA
golang:1.24.5   f14dd5573539        853MB             0B
```
Our image is $\approx 143.8$ times less than `golang:1.24.5` image

### Compose file
[Link](../compose.yaml)

### Persistence test
1. Creating a note
```sh
$ curl -X POST -H 'Content-Type: application/json' \
  -d '{"title":"durable","body":"survive a restart"}' \
  http://localhost:8080/notes
{"id":5,"title":"durable","body":"survive a restart","created_at":"2026-06-23T19:42:49.404403218Z"}
```
2. Verifification
```sh
$ curl -s http://localhost:8080/notes | jq | grep durable
"title": "durable",
```
3. Compose restarted
```sh
$ docker compose down
[+] down 2/2
 ✔ Container devops-intro-quicknotes-1 Removed
 ✔ Network devops-intro_default        Removed

$ docker compose up -d
[+] up 2/2
 ✔ Network devops-intro_default        Created
 ✔ Container devops-intro-quicknotes-1 Started

$ curl -s http://localhost:8080/notes | jq | grep durable
"title": "durable",
```
4. Compose restarted, deleting volume
```sh
$ docker compose down -v
[+] down 3/3
 ✔ Container devops-intro-quicknotes-1 Removed
 ✔ Volume devops-intro_quicknotes-data Removed
 ✔ Network devops-intro_default        Removed

$ docker compose up -d
[+] up 3/3
 ✔ Network devops-intro_default        Created
 ✔ Volume devops-intro_quicknotes-data Created
 ✔ Container devops-intro-quicknotes-1 Started

$ curl -s http://localhost:8080/notes | jq | grep durable
```

### Design questions
a) I structured the `Dockerfile` to leverage Docker's layer caching by placing `go mod download` before copying the rest of the source code. This ensures that heavy external dependencies are cached and not redownloaded on every single code change, reducing rebuild times from 30+ seconds to just 1–3 seconds.\
b) I used `CGO_ENABLED=0` to force the Go compiler to generate a fully statically linked binary with zero external C library dependencies. If I omit this flag, the binary dynamically looks for a Linux interpreter that does not exist in the empty `scratch` environment, causing the container to crash immediately with a "no such file or directory" error.\
c) This is an ultra-minimal base image that contains only the bare essentials for running an app like SSL certificates and a non-privileged user account, while entirely excluding shells, package managers, and standard Linux utilities. Emulating this approach allows me to minimize the container's attack surface, completely eliminating OS-level CVEs and preventing attackers from running malicious scripts.\
d) I used `-ldflags='-s -w'` to strip debugging symbols and DWARF data, which significantly optimizes and reduces the final binary size at the cost of losing interactive debugging capabilities. I added `-trimpath` to remove local development file system paths from the compiled binary, ensuring clean, reproducible builds while hiding the host directory structure in panic logs.\
e) Since the `scratch` container lacks a shell to interpret text commands, I injected a statically compiled `httpcheck` binary into `/bin/` during the multi-stage build. I invoke this tool directly using Docker's explicit JSON-array syntax (`["CMD", "/bin/httpcheck", ...]`), which bypasses the shell entirely and allows Docker to natively monitor the `/health` endpoint.\
f) The `quicknotes-data` named volume survives `docker compose down` because Docker intentionally isolates persistent data storage from the transient lifecycle of application containers. To completely destroy this volume and clear the data, I have to explicitly pass the volume flag using `docker compose down -v` or manually run `docker volume rm`.\
g) When using `depends_on` without conditions, Docker Compose only waits for the target container's OS process to spin up, not for the actual application inside to finish initializing. This introduces a race condition bug where the service can crash because it tries to connect to a database that is still performing internal startup routines.
