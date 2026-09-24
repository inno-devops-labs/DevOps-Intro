# Lab 6 submission

## Task 1: Multi-Stage Dockerfile

Dockerfile: [app/Dockerfile](../app/Dockerfile)

### Image size

```
$ docker images quicknotes:lab6
IMAGE             ID             DISK USAGE   CONTENT SIZE
quicknotes:lab6   fbf254529ba3       15.3MB          4.5MB

$ docker images golang:1.24 --format 'builder base: {{.Size}}'
builder base: 1.33GB
```

### Config

```
$ docker inspect quicknotes:lab6 | jq '.[0].Config | {User, ExposedPorts, Entrypoint, Env}'
{
  "User": "65532:65532",
  "ExposedPorts": {
    "8080/tcp": {}
  },
  "Entrypoint": [
    "/quicknotes"
  ],
  "Env": [
    "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
    "ADDR=:8080",
    "DATA_PATH=/data/notes.json",
    "SEED_PATH=/seed.json"
  ]
}

$ docker run -d --name qn-lab6 -p 8081:8080 quicknotes:lab6
$ curl -s http://localhost:8081/health
{"notes":4,"status":"ok"}
```

### Design questions

**a) Why does layer order matter?**

Every instruction's cache entry depends on all the instructions before it. Copying the whole source tree first means that changing any file invalidates that layer and everything below it, including the module download, so dependencies are resolved again on every edit. Copying go.mod first and the sources later keeps the dependency layer valid until the manifest itself changes, and only the compile step re-runs.

Measured on this project, rebuilding after appending one line to handlers.go:

| Strategy | No changes | After a source edit |
|---|---:|---:|
| go.mod copied first, sources later | 0.26 s | 3.80 s |
| whole tree copied first | 0.23 s | 3.36 s |

The two orderings measure the same here, and the cache-hostile one is even marginally faster, which is inside measurement noise. The reason is that QuickNotes has no dependencies at all, so go mod download has nothing to fetch and the layer the good ordering protects costs nothing to redo. The saving is exactly the cost of the steps kept valid, so on a project with real dependencies, where fetching and compiling them takes tens of seconds, the same reordering decides whether the edit loop is fast or slow.

**b) Why CGO_ENABLED=0?**

Cgo is enabled by default on Linux, and with it the net and os/user packages link against the system C library. The result is a dynamically linked binary that needs both libc and the dynamic loader at runtime. A scratch or distroless-static image contains neither, so the container exits immediately with "no such file or directory", which is confusing the first time because the missing file is the loader, not the binary that was just copied in. Disabling cgo selects the pure Go implementations and produces a fully static binary that needs nothing from the image around it.

**c) What is gcr.io/distroless/static:nonroot?**

A Google-maintained base image holding only what a static binary needs: CA certificates, timezone data, a writable /tmp, and an /etc/passwd with a nonroot user at UID 65532. It has no shell, no package manager, no libc and none of coreutils. That matters for CVEs because scanners report vulnerabilities per installed package, and an image with no OS packages produces no OS findings at all. The missing shell matters separately: a remote code execution bug is far less useful to an attacker who cannot then run sh, curl or apt. Scratch is not the same thing: it is a completely empty image, with no certificates, no timezone data and no /etc/passwd. This lab image is built on scratch, which takes the same idea one step further, and because there is no passwd file to resolve a name against the user has to be given as a numeric UID and GID. The Trivy scan below confirms the effect.

**d) What do the build flags do, and what do they cost?**

The -s flag drops the symbol table and -w drops the DWARF debugging information, which together remove several megabytes. The cost is debuggability: a debugger has no symbols to work with and post-mortem analysis of a core dump gets much harder, though Go panics still print function names because the runtime carries its own tables for that. The -trimpath flag strips absolute file system paths out of the binary and records module and package paths instead, so the build does not embed local directory names. That is one of the conditions for a reproducible build, not a guarantee on its own: the toolchain version and the rest of the build environment still have to match. Its cost is that a debugger no longer knows where the sources live.

---

## Task 2: Compose, Healthcheck, Persistent Volume

Compose file: [compose.yaml](../compose.yaml)

### Persistence test

```
$ HOST_PORT=8081 docker compose up --build -d
$ docker compose ps
NAME                        IMAGE             STATUS                   PORTS
devops-intro-quicknotes-1   quicknotes:lab6   Up 5 seconds (healthy)   0.0.0.0:8081->8080/tcp

$ curl -s -X POST -H 'Content-Type: application/json' \
    -d '{"title":"durable","body":"survive a restart"}' http://localhost:8081/notes
{"id":5,"title":"durable","body":"survive a restart","created_at":"2026-09-24T09:55:30.920083377Z"}

$ curl -s http://localhost:8081/notes | grep -o durable
durable

$ docker compose down
$ HOST_PORT=8081 docker compose up -d
$ curl -s http://localhost:8081/notes | grep -o durable
durable

$ docker compose down -v
 ✔ Volume devops-intro_quicknotes-data Removed
$ HOST_PORT=8081 docker compose up -d
$ curl -s http://localhost:8081/notes | grep -o durable || echo "gone (expected)"
gone (expected)
```

### Design questions

**e) Distroless has no shell, so how do you healthcheck it?**

I compile a second static binary in the builder stage and copy it into the image. It makes an HTTP request to the local /health endpoint and reports the result through its exit code, which is what Docker consumes, and Compose invokes it in exec form. It costs about 2 MB and keeps the image shell-free. The healthy status in the output above is that binary running.

The alternatives are worse. A sidecar probing the service from outside produces a health status belonging to the sidecar, so waiting on the real service with condition service_healthy still has nothing to wait for. Swapping in a debug image with wget or busybox puts a shell and a package set back into the runtime, undoing the second hardening default in order to gain a check. Relying on Docker noticing the process is alive is not a health check at all, because a server that has deadlocked or stopped accepting connections is still a running process.

**f) Why does the named volume survive docker compose down?**

Because a named volume is a separate Docker object with its own lifecycle, not a property of the container. The down command removes the containers and the network it created and deliberately leaves named volumes alone, so that data outlives the containers that used it. It is destroyed by down with the volumes flag, by removing the volume directly, by pruning volumes while nothing references it, or by removing Docker's data root. An anonymous volume survives down as well, but it has no name to reattach by. Compose carries one over while it recreates a container, and once down has removed that container the volume is reachable only by its ID, so the next up starts from a fresh empty one.

**g) What does depends_on without condition service_healthy actually wait for?**

Only for the dependency's container to be started, meaning created and running. It says nothing about whether the process inside is ready to accept work. The bug that follows is a race: the dependent service comes up, connects immediately, and gets a connection refused or an empty database, then either crashes or keeps running in a degraded state. It usually passes on a fast laptop where the dependency happens to be ready in time and fails in CI or on a loaded machine, which is why it tends to get blamed on the environment.

---

## Bonus Task: The 6 Security Defaults

### Hardened service block

```yaml
  quicknotes:
    build: ./app
    image: quicknotes:lab6
    ports:
      - "${HOST_PORT:-8080}:8080"
    environment:
      ADDR: ":8080"
      DATA_PATH: "/data/notes.json"
      SEED_PATH: "/seed.json"
    volumes:
      - quicknotes-data:/data
    healthcheck:
      test: ["CMD", "/healthcheck"]
      interval: 10s
      timeout: 3s
      retries: 3
      start_period: 5s
    restart: unless-stopped
    cap_drop:
      - ALL
    read_only: true
    tmpfs:
      - /tmp
    security_opt:
      - no-new-privileges:true
```

The non-root user and the minimal base, defaults 1 and 2, come from the Dockerfile.

### Verification

```
$ docker inspect quicknotes:lab6 --format '{{ .Config.User }}'
65532:65532

$ docker compose exec quicknotes sh
OCI runtime exec failed: exec failed: unable to start container process: exec: "sh": executable file not found in $PATH

$ docker inspect "$C" --format '{{ .HostConfig.CapDrop }}'
[ALL]

$ docker inspect "$C" --format '{{ .HostConfig.ReadonlyRootfs }}'
true

$ docker inspect "$C" --format '{{ .HostConfig.SecurityOpt }}'
[no-new-privileges:true]
```

The ReadonlyRootfs value above is the container's own setting. A write cannot be attempted from inside it, because the image holds no command capable of writing anything, so the same restriction was applied to an image that does have a shell, to show the runtime enforces the flag:

```
$ docker run --rm --read-only golang:1.24 sh -c 'touch /etc/test'
touch: cannot touch '/etc/test': Read-only file system
```

### Trivy

```
$ docker run --rm -v /tmp:/tmp public.ecr.aws/aquasecurity/trivy:0.59.1 image \
    --input /tmp/quicknotes-lab6.tar --severity HIGH,CRITICAL

healthcheck (gobinary)
Total: 19 (HIGH: 19, CRITICAL: 0)

quicknotes (gobinary)
Total: 19 (HIGH: 19, CRITICAL: 0)

All 19 findings, in both binaries, are the same stdlib entries:
stdlib v1.24.13, fixed in 1.25.x and 1.26.x
(CVE-2026-25679, CVE-2026-27145, CVE-2026-32280, CVE-2026-32281, CVE-2026-32283,
 CVE-2026-33811, CVE-2026-33814, CVE-2026-33818, CVE-2026-39820, CVE-2026-39821,
 CVE-2026-39822, CVE-2026-39836, CVE-2026-42499, CVE-2026-42504, CVE-2026-56853,
 CVE-2026-56858, CVE-2026-56859, CVE-2026-56860, CVE-2026-56862)
```

There are no OS package findings, because the image contains no OS packages. Every finding comes from the Go standard library compiled into the two binaries, and Trivy places the fixes in the 1.25.x and 1.26.x release lines, while the builder is pinned to Go 1.24. This class of finding is therefore fixed by rebuilding on a newer toolchain rather than by changing the image.

### Which default gives the most security per line

The base image choice is the strongest, and it costs no YAML at all: with no shell and no package manager, a code execution bug has nothing to pivot into, and the scan has nothing to report about the operating system. Among the lines actually written in Compose, dropping all capabilities wins, because one line removes the entire default set, including packet spoofing and user switching, none of which QuickNotes needs. The read-only root filesystem is close behind, since it removes the step almost every exploit chain needs, which is writing a payload somewhere and running it. Forbidding new privileges is the cheapest of the three, one line that makes setuid escalation impossible, though with no setuid binaries in the image it is defence in depth rather than a barrier that gets tested.
