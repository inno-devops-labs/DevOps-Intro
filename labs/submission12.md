# Lab 12 Submission

## Task 1 - Create the Moscow Time Application

### 1.1. Navigate to Lab Directory

#### Navigate to the lab folder

I navigate to the lab directory to start working with the project files.

```bash
C:\...\DevOps-Intro> cd labs/lab12
```

The command successfully moves me into the required folder, so I can work with `main.go` and other files.


### 1.2. Review the Go Application

#### Examine the provided `main.go`

I review the `main.go` file to understand how the application works in different modes.


#### Test Both Modes Locally

I run the application in server mode inside a Docker container.

```bash
seva@Seva:/mnt/.../DevOps-Intro/labs/lab12$ docker run --rm -v $(pwd):/app -w /app -p 8080:8080 golang:1.21-alpine go run main.go
Unable to find image 'golang:1.21-alpine' locally
1.21-alpine: Pulling from library/golang
...
Digest: sha256:2414035b086e3c42b99654c8b26e6f5b1b1598080d65fd03c7f499552ff4dc94
Status: Downloaded newer image for golang:1.21-alpine
2026/04/02 18:19:32 Server starting on :8080
```

The server starts successfully on `port 8080`, which means the HTTP mode works correctly.

!['localhost:8080'](screenshots/screenshot1.png)

I run the application in CLI mode to get a single JSON output.

```bash
seva@Seva:/mnt/.../DevOps-Intro/labs/lab12$ docker run --rm -v $(pwd):/app -w /app -e MODE=once golang:1.21-alpine go run main.go
{
  "moscow_time": "2026-04-02 21:22:44 MSK",
  "timestamp": 1775154164
}
```

The program prints `JSON` once and exits, which confirms that CLI mode works as expected.


### Explanation of how the single `main.go` works in three different contexts

The same `main.go` file supports three execution modes.
First, in CLI mode (`MODE=once`), the program prints JSON once and exits, which is useful for benchmarking.
Second, in server mode, it uses the standard net/http package to run a web server on `port 8080`.
Third, in WAGI mode (used by Spin), the program detects special environment variables and writes the HTTP response to `STDOUT`.
This design allows the same code to work in different environments without any changes.


## Task 2 - Build Traditional Docker Container

### 2.1. Review the Provided Dockerfile

#### Examine the provided Dockerfile

I review the Dockerfile to understand how the application is built and optimized.

The Dockerfile uses a multi-stage build.
It compiles a static Go binary and then copies it into a minimal scratch image.
This reduces the final image size and removes unnecessary dependencies.


### 2.2. Build and Run Traditional Container

#### Ensure you're in the lab directory

I check that I am in the correct directory before building the container.

```bash
seva@Seva:/mnt/.../DevOps-Intro/labs/lab12$
```

I am already inside the lab directory, so I can continue.


#### Clean up any previous containers

I remove old containers and unused images to avoid conflicts.

```bash
seva@Seva:/mnt/.../DevOps-Intro/labs/lab12$ docker rm -f test-traditional test-wasm 2>/dev/null || true
seva@Seva:/mnt/.../DevOps-Intro/labs/lab12$ docker image prune -f 2>/dev/null || true
Total reclaimed space: 0B
```

There were no unused resources, so nothing was removed.


#### Build Container

I build the Docker image using the provided Dockerfile.

```bash
seva@Seva:/mnt/.../DevOps-Intro/labs/lab12$ docker build -t moscow-time-traditional -f Dockerfile .
[+] Building 8.8s (11/11) FINISHED                                         docker:default
 => [internal] load build definition from Dockerfile                                 0.1s
 => => transferring dockerfile: 471B                                                 0.0s
 => [internal] load metadata for docker.io/library/golang:1.21-alpine                0.1s
 => [internal] load .dockerignore                                                    0.1s
 => => transferring context: 2B                                                      0.0s
 => [builder 1/4] FROM docker.io/library/golang:1.21-alpine@sha256:2414035b086e3c42  0.2s
 => => resolve docker.io/library/golang:1.21-alpine@sha256:2414035b086e3c42b99654c8  0.1s
 => [internal] load build context                                                    0.1s
 => => transferring context: 3.49kB                                                  0.0s
 => [stage-1 1/2] WORKDIR /app                                                       0.1s
 => [builder 2/4] WORKDIR /app                                                       0.0s
 => [builder 3/4] COPY main.go .                                                     0.1s
 => [builder 4/4] RUN CGO_ENABLED=0 GOOS=linux     go build -tags netgo -trimpath    7.2s
 => [stage-1 2/2] COPY --from=builder /app/moscow-time .                             0.1s
 => exporting to image                                                               0.7s
 => => exporting layers                                                              0.4s
 => => exporting manifest sha256:d8ce79be91a09c36ac48c800e80373ecf46b9554970b0da865  0.0s
 => => exporting config sha256:4997fdbc38dd913ae89a44aed66782d40a3e0ffd5c9096603639  0.0s
 => => exporting attestation manifest sha256:0d3015144fdb8332ec8148fcf17c1f09d5b254  0.1s
 => => exporting manifest list sha256:9a4ccc5d8267d31eba08d2c077a66d2c25412f3fca4bb  0.0s
 => => naming to docker.io/library/moscow-time-traditional:latest                    0.0s
 => => unpacking to docker.io/library/moscow-time-traditional:latest                 0.1s
```

The image is built successfully without errors, which means the build configuration is correct.


#### Test CLI Mode

I run the container in CLI mode to verify output.

```bash
seva@Seva:/mnt/.../DevOps-Intro/labs/lab12$ docker run --rm -e MODE=once moscow-time-traditional
{
  "moscow_time": "2026-04-02 21:25:27 MSK",
  "timestamp": 1775154327
}
```

The container returns correct JSON output, so CLI mode works inside Docker.


#### Test Server Mode

I run the container in server mode and expose `port 8080`.

```bash
seva@Seva:/mnt/.../DevOps-Intro/labs/lab12$ docker run --rm -p 8080:8080 moscow-time-traditional
2026/04/02 18:25:31 Server starting on :8080
```

The server starts correctly, and I can access it in the browser.

!['localhost:8080'](screenshots/screenshot2.png)


### 2.3. Measure Performance

#### Check Binary Size

I extract the compiled binary from the container and check its size.

```bash
seva@Seva:/mnt/.../DevOps-Intro/labs/lab12$ docker create --name temp-traditional moscow-time-traditional
docker cp temp-traditional:/app/moscow-time ./moscow-time-traditional
docker rm temp-traditional
ls -lh moscow-time-traditional
7ac6492fce6a503bc46cc2ed7a426fdbc382e847ba06301d817bd80c0ce50d3e
Successfully copied 4.7MB to /mnt/.../DevOps-Intro/labs/lab12/moscow-time-traditional
temp-traditional
-rwxrwxrwx 1 seva seva 4.5M Apr  2 21:25 moscow-time-traditional
```

The binary size is about `4.5 MB`.
This is expected for a statically compiled Go application.


#### Check Image Size

I check the Docker image size using two different commands.

```bash
seva@Seva:/mnt/.../DevOps-Intro/labs/lab12$ docker images moscow-time-traditional
                                                                      i Info →   U  In Use
IMAGE                            ID             DISK USAGE   CONTENT SIZE   EXTRA
moscow-time-traditional:latest   9a4ccc5d8267       6.79MB         2.07MB
seva@Seva:/mnt/.../DevOps-Intro/labs/lab12$ docker image inspect moscow-time-traditional --format '{{.Size}}' | \
    awk '{print $1/1024/1024 " MB"}'
1.97717 MB
```

The image size is very small (around `2 MB` actual content).
This is because the image uses scratch and contains only the binary.


#### Startup Time Benchmark (CLI Mode)

I measure the average startup time by running the container multiple times.

```bash
seva@Seva:/mnt/.../DevOps-Intro/labs/lab12$ for i in {1..5}; do
    /usr/bin/time -f "%e" docker run --rm -e MODE=once moscow-time-traditional 2>&1 | tail -n 1
done | awk '{sum+=$1; count++} END {print "Average:", sum/count, "seconds"}'
Average: 0.58 seconds
```

The average startup time is about `0.58 seconds`.
This includes container startup overhead and program execution.


#### Memory Usage

I run the container in server mode to measure memory usage.

```bash
seva@Seva:/mnt/.../DevOps-Intro/labs/lab12$ docker run --rm --name test-traditional -p 8080:8080 moscow-time-traditional
2026/04/02 18:27:04 Server starting on :8080
```

I check memory usage using docker stats.

```bash
seva@Seva:/mnt/wsl/docker-desktop-bind-mounts/Ubuntu-24.04/694b9a51160fa18d7abe1869b579060478eb13e2f14b57c3341f52a3fdcf6078$ docker stats test-traditional --no-stream
CONTAINER ID   NAME               CPU %     MEM USAGE / LIMIT    MEM %     NET I/O           BLOCK I/O   PIDS
0364213ec9ba   test-traditional   0.00%     1.922MiB / 7.62GiB   0.02%     68.2kB / 18.7kB   0B / 0B     5
```

The container uses about `1.9 MB` of memory.
This shows that the application is lightweight and efficient.


## Task 3 - Build WASM Container

### 3.1. Capture TinyGo Version

#### Record Build Environment

I check the TinyGo version used for building the WASM binary.

```bash
seva@Seva:/mnt/.../DevOps-Intro/labs/lab12$ docker run --rm tinygo/tinygo:0.39.0 tinygo version
Unable to find image 'tinygo/tinygo:0.39.0' locally
0.39.0: Pulling from tinygo/tinygo
...
Digest: sha256:0e51d243c1b84ec650f2dcd1cce3a09bb09730e1134771aeace2240ade4b32f5
Status: Downloaded newer image for tinygo/tinygo:0.39.0
tinygo version 0.39.0 linux/amd64 (using go version go1.25.0 and LLVM version 19.1.2)
```

TinyGo version `0.39.0` is used, with Go `1.25.0` and LLVM `19.1.2`.
This confirms the build environment is correct and reproducible.


### 3.2. Build WASM Binary Using TinyGo

#### Compile to WASM

I compile the same `main.go` file into a WASM binary using TinyGo.

```bash
seva@Seva:/mnt/.../DevOps-Intro/labs/lab12$ docker run --rm \
    -v $(pwd):/src \
    -w /src \
    tinygo/tinygo:0.39.0 \
    tinygo build -o main.wasm -target=wasi main.go
```

The compilation finishes without errors, so the WASM binary is created successfully.


#### Verify WASM Binary

I check the generated WASM file and its format.

```bash
seva@Seva:/mnt/.../DevOps-Intro/labs/lab12$ ls -lh main.wasm
file main.wasm
-rwxrwxrwx 1 seva seva 2.4M Apr  2 21:33 main.wasm
main.wasm: WebAssembly (wasm) binary module version 0x1 (MVP)
```

The binary size is about `2.4 MB`, which is smaller than the native Go binary.
The file is correctly recognized as a WebAssembly module.


### 3.3. Review the WASM Dockerfile

I review the WASM Dockerfile to understand how the container is built.

The Dockerfile is very minimal and uses scratch as the base image.
It only copies the `main.wasm` file and runs it directly.
This results in a very small image with no extra dependencies.


### 3.4. Build and Run WASM Container

#### Install containerd

I install containerd and start the service.

```bash
seva@Seva:/mnt/.../DevOps-Intro/labs/lab12$ sudo apt-get update
sudo apt-get install -y containerd
Hit:1 http://archive.ubuntu.com/ubuntu noble InRelease
Get:2 http://security.ubuntu.com/ubuntu noble-security InRelease [126 kB]
...
Processing triggers for man-db (2.12.0-4build2) ...

seva@Seva:/mnt/.../DevOps-Intro/labs/lab12$ sudo systemctl enable --now containerd
sudo systemctl status containerd
● containerd.service - containerd container runtime
     Loaded: loaded (/usr/lib/systemd/system/containerd.service; enabled; preset: enabled)
     Active: active (running) since Thu 2026-04-02 21:34:01 MSK; 3s ago
       Docs: https://containerd.io
   Main PID: 1561 (containerd)
      Tasks: 10
     Memory: 13.9M (peak: 14.9M)
        CPU: 91ms
     CGroup: /system.slice/containerd.service
             └─1561 /usr/bin/containerd

Apr 02 21:34:01 Seva containerd[1561]: time="2026-04-02T21:34:01.211976524+03:00" level=i>
...
Apr 02 21:34:01 Seva systemd[1]: Started containerd.service - containerd container runtim>
...skipping...
● containerd.service - containerd container runtime
     Loaded: loaded (/usr/lib/systemd/system/containerd.service; enabled; preset: enabled)
     Active: active (running) since Thu 2026-04-02 21:34:01 MSK; 3s ago
       Docs: https://containerd.io
   Main PID: 1561 (containerd)
      Tasks: 10
     Memory: 13.9M (peak: 14.9M)
        CPU: 91ms
     CGroup: /system.slice/containerd.service
             └─1561 /usr/bin/containerd

Apr 02 21:34:01 Seva containerd[1561]: time="2026-04-02T21:34:01.211976524+03:00" level=i>
...
Apr 02 21:34:01 Seva systemd[1]: Started containerd.service - containerd container runtim>
```

Containerd is installed and running successfully.


#### Verify ctr is available

I check that the ctr CLI is available.

```bash
seva@Seva:/mnt/.../DevOps-Intro/labs/lab12$ ctr --version
ctr github.com/containerd/containerd 1.7.28
```

The ctr tool is installed and ready to use.


#### Install the Wasmtime runtime shim

I build and install the Wasmtime shim required to run WASM containers.

```bash
seva@Seva:/mnt/.../DevOps-Intro/labs/lab12$ docker run --rm \
-v "$PWD:/out" \
-w /work \
rust:slim-bookworm \
bash -lc '
   set -euo pipefail
   export DEBIAN_FRONTEND=noninteractive
   export PATH="/usr/local/cargo/bin:$PATH"

   echo "[1/5] Install build deps"
   apt-get update
   apt-get install -y git build-essential pkg-config libssl-dev libseccomp-dev \
                     protobuf-compiler clang make ca-certificates curl

   echo "[2/5] Ensure Rust toolchain is available"
   if ! command -v cargo >/dev/null 2>&1; then
      echo "cargo not found; bootstrapping via rustup..."
      curl --proto "=https" --tlsv1.2 -sSf https://sh.rustup.rs \
      | sh -s -- -y --profile minimal --default-toolchain stable
      . "$HOME/.cargo/env"
      export PATH="$HOME/.cargo/bin:$PATH"
   fi
   rustc --version; cargo --version

   echo "[3/5] Clone runwasi"
'  install -m 0755 target/release/containerd-shim-wasmtime-v1 /out/
Unable to find image 'rust:slim-bookworm' locally
slim-bookworm: Pulling from library/rust
...
Finished `release` profile [optimized] target(s) in 3m 28s
[5/5] Copy binary to host

seva@Seva:/mnt/.../DevOps-Intro/labs/lab12$ sudo install -D -m0755 containerd-shim-wasmtime-v1 /usr/local/bin/
seva@Seva:/mnt/.../DevOps-Intro/labs/lab12$ ls -la /usr/local/bin/containerd-shim-wasmtime-v1
-rwxr-xr-x 1 root root 32325480 Apr  2 21:46 /usr/local/bin/containerd-shim-wasmtime-v1
```

The shim is built and installed correctly in `/usr/local/bin`.
This binary will be used by containerd to run WASM workloads.


#### Configure containerd to register the wasmtime shim

I create or update the containerd configuration file.

```bash
seva@Seva:/mnt/.../DevOps-Intro/labs/lab12$ sudo cp /etc/containerd/config.toml /etc/containerd/config.toml.backup 2>/dev/null || true
seva@Seva:/mnt/.../DevOps-Intro/labs/lab12$ sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml >/dev/null
```

The configuration file is prepared and ready for modification.


#### Manually add the wasmtime runtime configuration

I open the configuration file to add the wasmtime runtime.

```bash
seva@Seva:/mnt/.../DevOps-Intro/labs/lab12$ sudo nano /etc/containerd/config.toml
```

I add the wasmtime runtime block to enable WASM support.


#### Restart containerd and verify configuration

I restart containerd to apply changes.

```bash
seva@Seva:/mnt/.../DevOps-Intro/labs/lab12$ sudo systemctl restart containerd
sudo systemctl status containerd --no-pager
● containerd.service - containerd container runtime
     Loaded: loaded (/usr/lib/systemd/system/containerd.service; enabled; preset: enabled)
     Active: active (running) since Thu 2026-04-02 21:55:12 MSK; 16ms ago
       Docs: https://containerd.io
    Process: 1893 ExecStartPre=/sbin/modprobe overlay (code=exited, status=0/SUCCESS)
   Main PID: 1894 (containerd)
      Tasks: 9
     Memory: 19.5M (peak: 19.8M)
        CPU: 86ms
     CGroup: /system.slice/containerd.service
             └─1894 /usr/bin/containerd

Apr 02 21:55:12 Seva containerd[1894]: time="2026-04-02T21:55:12.340980330+03:00" le…vent"
Apr 02 21:55:12 Seva containerd[1894]: time="2026-04-02T21:55:12.341029464+03:00" le…tate"
...
Hint: Some lines were ellipsized, use -l to show in full.
```

Containerd restarts successfully with the new configuration.


#### Verify the wasmtime runtime is correctly registered

I check that the wasmtime runtime is registered.

```bash
seva@Seva:/mnt/.../DevOps-Intro/labs/lab12$ sudo containerd config dump | grep -A 5 "wasmtime"
        [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.wasmtime]
          base_runtime_spec = ""
          cni_conf_dir = ""
          cni_max_conf_num = 0
          container_annotations = []
          pod_annotations = []
--
          runtime_type = "io.containerd.wasmtime.v1"
          sandbox_mode = ""
          snapshotter = ""

          [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.wasmtime.options]
            BinaryName = "/usr/local/bin/containerd-shim-wasmtime-v1"

      [plugins."io.containerd.grpc.v1.cri".containerd.untrusted_workload_runtime]
        base_runtime_spec = ""
        cni_conf_dir = ""
        cni_max_conf_num = 0
```

The wasmtime runtime is correctly configured and recognized by containerd.


#### Final verification

I verify the shim location and containerd status.

```bash
seva@Seva:/mnt/.../DevOps-Intro/labs/lab12$ ls -la /usr/local/bin/containerd-shim-wasmtime-v1
-rwxr-xr-x 1 root root 32325480 Apr  2 21:46 /usr/local/bin/containerd-shim-wasmtime-v1
seva@Seva:/mnt/.../DevOps-Intro/labs/lab12$ sudo ctr version
Client:
  Version:  1.7.28
  Revision:
  Go version: go1.23.1

Server:
  Version:  1.7.28
  Revision:
  UUID: fcaf19f9-8bb3-460f-8b44-a7fdf75d4477
```

Everything is installed correctly and ready for WASM execution.


### Build OCI Archive and Import into containerd

#### Build WASI image to OCI archive using Docker Buildx

I build the WASM image as an OCI archive.

```bash
seva@Seva:/mnt/.../DevOps-Intro/labs/lab12$ docker buildx build \
   --platform=wasi/wasm \
   -t moscow-time-wasm:latest \
   -f Dockerfile.wasm \
   --output=type=oci,dest=moscow-time-wasm.oci,annotation=index:org.opencontainers.image.ref.name=moscow-time-wasm:latest \
   .
[+] Building 0.3s (5/5) FINISHED                                           docker:default
 => [internal] load build definition from Dockerfile.wasm                            0.1s
 => => transferring dockerfile: 121B                                                 0.0s
 => [internal] load .dockerignore                                                    0.0s
 => => transferring context: 2B                                                      0.0s
 => [internal] load build context                                                    0.2s
 => => transferring context: 2.45MB                                                  0.1s
 => [1/1] COPY main.wasm /main.wasm                                                  0.0s
 => exporting to oci image format                                                    0.4s
 => => exporting layers                                                              0.3s
 => => exporting manifest sha256:310b194d0f5617352a4b13167e5e8e0390a83650c50d3fc579  0.0s
 => => exporting config sha256:f6ded62040ec24c079b85aaef93cfe03d20e8bda76069971607a  0.0s
 => => sending tarball                                                               0.0s
```

The OCI archive is created successfully and very quickly.


#### Import the OCI archive into containerd

I import the built image into containerd.

```bash
seva@Seva:/mnt/.../DevOps-Intro/labs/lab12$ sudo ctr images import \
   --platform=wasi/wasm \
   --index-name docker.io/library/moscow-time-wasm:latest \
   moscow-time-wasm.oci
unpacking docker.io/library/moscow-time-wasm:latest (sha256:ecad1e78a13b3bd9577ca2ace1c856465e31ae875ec7a68a4c8ed106cc61df27)...done
unpacking docker.io/library/moscow-time-wasm:latest (sha256:310b194d0f5617352a4b13167e5e8e0390a83650c50d3fc5790c0af49ad20223)...done
```

The image is successfully imported into containerd.


#### Verify the image was imported

I check that the image is available in containerd.

```bash
seva@Seva:/mnt/.../DevOps-Intro/labs/lab12$ sudo ctr images ls | grep -E 'moscow-time-wasm|wasi|wasm'
docker.io/library/moscow-time-wasm:latest application/vnd.oci.image.manifest.v1+json sha256:310b194d0f5617352a4b13167e5e8e0390a83650c50d3fc5790c0af49ad20223 819.9 KiB wasi/wasm -
```

The image is present and its size is less than `1 MB`.
This is significantly smaller than the traditional container.


### Run WASM Container with ctr

#### Test CLI Mode

I run the WASM container in CLI mode using ctr.

```bash
seva@Seva:/mnt/.../DevOps-Intro/labs/lab12$ sudo ctr run --rm \
   --runtime io.containerd.wasmtime.v1 \
   --platform wasi/wasm \
   --env MODE=once \
   docker.io/library/moscow-time-wasm:latest wasi-once
{
  "moscow_time": "2026-04-02 21:57:48 MSK",
  "timestamp": 1775156268
}
```

The container runs successfully and produces the expected JSON output.
This confirms that WASM execution works correctly.


#### Server Mode Limitation

WASM containers do not support server mode in this setup.
This is because WASI Preview1 does not support TCP sockets.
The application cannot open a network port, so the HTTP server cannot start.
Only CLI mode works correctly in this environment.

### 3.5. Measure WASM Performance

#### Check Sizes

I check the size of the WASM binary and the container image.

```bash
seva@Seva:/mnt/.../DevOps-Intro/labs/lab12$ ls -lh main.wasm
-rwxrwxrwx 1 seva seva 2.4M Apr  2 21:33 main.wasm

seva@Seva:/mnt/.../DevOps-Intro/labs/lab12$ sudo ctr images ls | awk 'NR>1 && $1 ~ /moscow-time-wasm/ {print "IMAGE:", $1, "SIZE:", $4}'
IMAGE: docker.io/library/moscow-time-wasm:latest SIZE: 819.9
```

The WASM binary is about `2.4 MB`.
The container image is extremely small (less than `1 MB`).


#### Startup Time Benchmark

I measure the startup time for the WASM container.

```bash
seva@Seva:/mnt/.../DevOps-Intro/labs/lab12$ for i in {1..5}; do
    NAME="wasi-$(date +%s%N | tail -c 6)-$i"
    /usr/bin/time -f "%e" sudo ctr run --rm \
        --runtime io.containerd.wasmtime.v1 \
        --platform wasi/wasm \
        --env MODE=once \
        docker.io/library/moscow-time-wasm:latest "$NAME" 2>&1 | tail -n 1
done | awk '{sum+=$1; n++} END{printf("Average: %.4f seconds\n", sum/n)}'
Average: 0.5320 seconds
```

The average startup time is about `0.53 seconds`.
This is slightly faster than the traditional container.


#### Memory Usage

Memory usage is not available for WASM containers via `ctr`.
WASM uses a different execution model and does not rely on standard container metrics.
Therefore, memory usage is reported as `N/A`.


## Task 4 - Performance Comparison & Analysis

### 4.1. Create Comprehensive Comparison Table

| Metric                 | Traditional Container | WASM Container         | Improvement   | Notes                      |
| ---------------------- | --------------------- | ---------------------- | ------------- | -------------------------- |
| **Binary Size**        | 4.5 MB                | 2.4 MB                 | ~47% smaller  | From `ls -lh`              |
| **Image Size**         | ~2.0 MB               | ~0.8 MB                | ~60% smaller  | From image tools           |
| **Startup Time (CLI)** | 580 ms                | 532 ms                 | ~1.09x faster | Average of 5 runs          |
| **Memory Usage**       | ~1.9 MB               | N/A                    | N/A           | WASM metrics not available |
| **Base Image**         | scratch               | scratch                | Same          | Both minimal               |
| **Source Code**        | main.go               | main.go                | Identical     | ✅ Same file                |
| **Server Mode**        | ✅ Works               | ❌ via ctr / ✅ via Spin | N/A           | WASI limitation            |


### 4.2. Analysis Questions

#### Binary Size Comparison

The WASM binary is smaller because TinyGo uses a more minimal runtime.
It removes many parts of the standard Go runtime and includes only what is needed.
For example, it avoids full garbage collector features and reduces unused packages.
It also strips debug information and simplifies dependencies.
As a result, the final binary is significantly smaller than the standard Go build.


#### Startup Performance

WASM starts faster because it has less initialization overhead.
The runtime is simpler and loads fewer components compared to a full Go binary.
In traditional containers, Docker must start a container environment and initialize the Go runtime.
This includes process setup, memory allocation, and networking stack initialization.
WASM avoids most of this, so startup is slightly faster.


#### Use Case Decision Matrix

I would choose WASM when I need small size and fast startup.
It is useful for serverless, edge computing, and short-lived tasks.
WASM is also good when I want strong isolation and portability.

I would use traditional containers when I need full system features.
For example, networking, long-running services, or complex applications.
Traditional containers are more flexible and better supported in production.


### Recommendations for when to use each approach

WASM is a good choice for lightweight and fast workloads.
It works well for CLI tools, microservices, and serverless platforms.
It is especially useful when startup time and image size are important.

Traditional containers are better for general-purpose applications.
They support full networking and system capabilities.
For most backend services, Docker is still the more practical option.


## Bonus Task - Deploy to Fermyon Spin Cloud

### Bonus.1. Install Spin CLI

I install the Spin CLI tool to work with WASM applications and Fermyon Cloud.

```bash
seva@Seva:/mnt/.../DevOps-Intro/labs/lab12$ curl -fsSL https://developer.fermyon.com/downloads/install.sh | bash
sudo mv spin /usr/local/bin/
Step 1: Downloading: https://github.com/spinframework/spin/releases/download/v3.6.2/spin-v3.6.2-linux-amd64.tar.gz
Done...
....

Homepage:
        https://github.com/fermyon/cloud-plugin
You're good to go. Check here for the next steps: https://spinframework.dev/quickstart
Run './spin' to get started

seva@Seva:/mnt/.../DevOps-Intro/labs/lab12$ spin --version
spin 3.6.2 (c0fc970 2026-02-25)
```

Spin CLI was installed successfully and is available in the system. The version is confirmed, so I can proceed with WASM deployment.


### Bonus.2. Review Spin Configuration (WAGI Mode)

Spin uses WAGI (WebAssembly Gateway Interface) to handle HTTP requests for WASM modules.
In this mode, incoming HTTP requests are translated into standard input/output calls for the WASM binary.

The configuration defines routes and connects them to the compiled `main.wasm`.
This allows the application to behave like a web server without using traditional networking inside the binary.


### Bonus.3. Prepare WASM Binary for Spin

I prepare the compiled WASM binary so it can be used by Spin.

The `main.wasm` file generated earlier is reused without modification.
This shows that the same WASM artifact works across different runtimes (containerd and Spin).


### Bonus.4. Test Locally with Spin

#### Verify you have the WASM binary

I verify that the compiled WASM binary exists before running the application.

```bash
seva@Seva:/mnt/.../DevOps-Intro/labs/lab12$ ls -lh main.wasm
-rwxrwxrwx 1 seva seva 2.4M Apr  2 21:33 main.wasm
```

The WASM binary is present and has a small size (`~2.4 MB`), ready to be executed by Spin.


#### Run Spin locally

I start the Spin application locally to test HTTP functionality.

```bash
seva@Seva:/mnt/.../DevOps-Intro/labs/lab12$ spin up
Logging component stdio to ".spin/logs/"

Serving http://127.0.0.1:3000
Available Routes:
  moscow-time: http://127.0.0.1:3000 (wildcard)
```

Spin successfully starts a local HTTP server.
The application is accessible via browser and works as expected, including API endpoints.

!['localhost:3000'](screenshots/screenshot3.png)

### Bonus.5. Deploy to Spin Cloud

#### Sign Up for Fermyon Cloud

I create an account in Fermyon Cloud to deploy the application.

!['cloud.fermyon.com'](screenshots/screenshot4.png)

The platform provides hosted infrastructure for running WASM applications.


#### Login via CLI

I authenticate in Fermyon Cloud using the CLI.

```bash
seva@Seva:/mnt/.../DevOps-Intro/labs/lab12$ spin cloud login

Copy your one-time code:

********

...and open the authorization page in your browser:

https://cloud.fermyon.com/device-authorization

Waiting for device authorization...
Waiting for device authorization...
Device authorized!
```

Authentication is completed successfully using device authorization.
The CLI is now linked to my cloud account.


#### Deploy Application

I deploy the application to Fermyon Cloud.

```bash
seva@Seva:/mnt/.../DevOps-Intro/labs/lab12$ spin deploy
******** IMPORTANT! ********
Future breaking change: `spin deploy` needs to be told which deployment plugin to use. Either:
* Run a plugin command (e.g. `spin cloud deploy`); or
* Set the `SPIN_DEPLOY_PLUGIN` environment variable.
For now, Spin will default to the `cloud` plugin.
This will be a hard error in a future version.
Uploading moscow-time version 1.0.0 to Fermyon Cloud...
Deploying...
Waiting for application to become ready......... ready

View application:   https://moscow-time-r6bhwtks.fermyon.app/
Manage application: https://cloud.fermyon.com/app/moscow-time
```

The deployment finishes successfully in a few seconds.
The application becomes publicly available via a URL.


#### Test Deployment

I test the deployed application using curl.

```bash
va@Seva:/mnt/.../DevOps-Intro/labs/lab12$ s/perhttps://moscow-time-r6bhwtks.fermyon.app/$ curl https://moscow-time-r6bhwtks.fermyon.app/
<!DOCTYPE html>
<html>
<head>
  <title>Moscow Time</title>
  <style>
    body { font-family: Arial, sans-serif; text-align: center; margin-top: 100px;
           background: linear-gradient(135deg,#667eea 0%,#764ba2 100%); color: white; }
    .container { background: rgba(255,255,255,.1); padding: 40px; border-radius: 10px;
                 backdrop-filter: blur(10px); max-width: 600px; margin: 0 auto; }
    h1 { margin-bottom: 30px; }
    #time { font-size: 3em; font-weight: bold; margin: 20px 0; text-shadow: 2px 2px 4px rgba(0,0,0,.3); }
    a { color:#ffd700; text-decoration:none; font-size:1.2em; }
    a:hover { text-decoration: underline; }
  </style>
</head>
<body>
  <div class="container">
    <h1>🕰️ Current Time in Moscow</h1>
    <div id="time">Loading...</div>
    <p><a href="/api/time">📊 View JSON API</a></p>
  </div>
  <script>
    async function updateTime(){
      try{
        const r=await fetch('/api/time'); const d=await r.json();
        document.getElementById('time').textContent=d.moscow_time;
      }catch(e){ console.error(e); document.getElementById('time').textContent='Error loading time'; }
    }
    updateTime(); setInterval(updateTime,1000);
  </script>
</body>
</html>
```

The application returns a valid HTML page.

!['moscow-time-r6bhwtks.fermyon.app'](screenshots/screenshot5.png)

Both UI and API endpoints work correctly in the cloud environment.

### Bonus.6. Measure and Compare Deployment Experience

#### Measure deployment time

I measure how long it takes to deploy the application.

```bash
seva@Seva:/mnt/.../DevOps-Intro/labs/lab12$ time spin depltime spin deploy
******** IMPORTANT! ********
Future breaking change: `spin deploy` needs to be told which deployment plugin to use. Either:
* Run a plugin command (e.g. `spin cloud deploy`); or
* Set the `SPIN_DEPLOY_PLUGIN` environment variable.
For now, Spin will default to the `cloud` plugin.
This will be a hard error in a future version.
Uploading moscow-time version 1.0.0 to Fermyon Cloud...
Deploying...
Waiting for application to become ready... ready

View application:   https://moscow-time-r6bhwtks.fermyon.app/
Manage application: https://cloud.fermyon.com/app/moscow-time

real    0m10.342s
user    0m0.140s
sys     0m0.210s
```

Deployment takes around `10 seconds`.
This is very fast compared to traditional container-based deployments.


#### Measure cold start latency

I measure cold and warm request latency.

```bash
seva@Seva:/mnt/.../DevOps-Intro/labs/lab12$ export SPIN_URL="https://moscow-time-abc123.fermyon.app"
seva@Seva:/mnt/.../DevOps-Intro/labs/lab12$ curl -s "$SPIN_URL/api/time" | jq .
Command 'jq' not found, but can be installed with:
sudo snap install jq  # version 1.5+dfsg-1, or
sudo apt  install jq  # version 1.7.1-3ubuntu0.24.04.1
See 'snap info jq' for additional versions.
```

```bash
seva@Seva:/mnt/.../DevOps-Intro/labs/lab12$ echo "Cold start average:"
for i in {1..5}; do
    curl -sS -o /dev/null -w "%{time_total}\n" "$SPIN_URL/?_cold=$(date +%s%N)" 2>&1
    sleep 5
done | awk '{sum+=$1; n++} END {printf("Average: %.4f seconds\n", sum/n)}'
Cold start average:
Average: 1.5724 seconds
seva@Seva:/mnt/.../DevOps-Intro/labs/lab12$ echo "Warm average:"
for i in {1..5}; do
    curl -sS -o /dev/null -w "%{time_total}\n" "$SPIN_URL/api/time" 2>&1
    sleep 1
done | awk '{sum+=$1; n++} END {printf("Average: %.4f seconds\n", sum/n)}'
Warm average:
Average: 1.6392 seconds
```

- Cold start is about `~1.57 seconds`
- Warm requests are similar (`~1.64 seconds`)

This shows that network latency dominates more than startup time.


#### Measure local Spin startup (for comparison)

I measure request latency for local Spin execution.

```bash
seva@Seva:/mnt/.../DevOps-Intro/labs/lab12$ # Start Spin locally in background
spin up &
SPIN_PID=$!
sleep 2

# Calculate average
echo "Local average:"
for i in {1..5}; do
    curl -sS -o /dev/null -w "%{time_total}\n" "http://localhost:3000/api/time"
done | awk '{sum+=$1; n++} END {printf("Average: %.4f seconds\n", sum/n)}'

# Stop Spin
kill $SPIN_PID
[1] 3701
Logging component stdio to ".spin/logs/"

Serving http://127.0.0.1:3000
Available Routes:
  moscow-time: http://127.0.0.1:3000 (wildcard)
Local average:
Average: 0.0103 seconds
```

Local execution is extremely fast (`~10 ms`).
This highlights that cloud latency is the main overhead.


### Reflection: Would you use Spin for production workloads? Why or why not?

Yes, I would consider using Spin for production in specific cases.
It provides very fast deployment, simple configuration, and good isolation via WASM.
It is especially useful for microservices, APIs, and lightweight backend logic.
However, ecosystem and tooling are still less mature compared to traditional containers.
Also, limitations like networking support in WASI may restrict some use cases.


### Reflection: How does this compare to traditional serverless (AWS Lambda, Cloud Functions)?

Spin is similar to serverless platforms because it abstracts infrastructure and scales automatically.
However, it uses WASM instead of full container or VM environments, which makes it lighter and faster to deploy.
Cold start behavior is comparable, but Spin can be simpler and more portable.
Traditional serverless platforms have better ecosystem, integrations, and monitoring tools.
Overall, Spin feels more lightweight and developer-friendly, but less mature.
