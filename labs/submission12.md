# Lab 12 — WebAssembly Containers vs Traditional Containers

**Student:** Kamilya Shakirova  
**Date:** 21-04-2026  

---

## Task 1 — Create the Moscow Time Application

- [x] Screenshot of CLI mode output (`MODE=once`)
- [x] Screenshot of server mode running in browser (if tested)
- [x] Confirmation that you're working directly in `labs/lab12/` directory
- [x] Explanation of how the single `main.go` works in three different contexts

### 1.1 Navigate to Lab Directory

1. **Navigate to the lab folder:**

```bash
kamilya@Kama:/mnt/d/Programs/DevOps-Intro$ cd labs/lab12
```

   > **Note:** The `main.go` and `spin.toml` reference files are already provided in this directory. You'll work directly here for all tasks.

### 1.2 Review the Go Application

1. **Examine the provided `main.go`:**

   This single file works in **three different execution contexts**:
   - **CLI mode** (`MODE=once`): Prints JSON once and exits → used for benchmarking in both Docker and WASM
   - **Traditional server mode** (`net/http`): Runs a standard Go HTTP server → works in Docker
   - **WAGI mode** (Spin): Detects CGI-style environment variables and responds via STDOUT → works in Spin

   **Key Implementation Details:**
   
   - `isWagi()` function detects if running under Spin by checking for `REQUEST_METHOD` env var
   - `runWagiOnce()` handles a single HTTP request by printing headers and body to STDOUT (CGI/WAGI style)
   - Falls back to standard `net/http` server if not in CLI or WAGI mode
   - Uses `time.FixedZone` instead of `time.LoadLocation` (timezone databases may not be available in minimal WASM environments)

   > **Why this works:** Spin's WAGI executor starts your WASM per request, sets CGI-style environment variables (`REQUEST_METHOD`, `PATH_INFO`), and expects HTTP headers + body on STDOUT. No Spin SDK needed!

   The file is already in `labs/lab12/main.go` - review the code to understand:
   - How `isWagi()` detects the execution context
   - How `runWagiOnce()` handles CGI-style requests
   - How the same code works in all three modes

2. **Test Both Modes Locally (Optional):**

```bash
# Test server mode
kamilya@Kama:/mnt/d/Programs/DevOps-Intro/labs/lab12$ sudo snap install go --classic
[sudo] password for kamilya: 
go 1.26.2 from Canonical✓ installed
kamilya@Kama:/mnt/d/Programs/DevOps-Intro/labs/lab12$ go run main.go
2026/04/21 17:33:54 Server starting on :8080
# Visit http://localhost:8080 in another terminal

# Test CLI mode
kamilya@Kama:/mnt/d/Programs/DevOps-Intro/labs/lab12$ MODE=once go run main.go
{
  "moscow_time": "2026-04-21 17:35:31 MSK",
  "timestamp": 1776782131
}
```
![alt text](screenshots/image.png)

### 1.3 How the single `main.go` works in three different contexts

The same code automatically detects its environment:

| Mode | Detection | Behavior |
|------|-----------|----------|
| **CLI** | `MODE=once` env var | Prints JSON once and exits |
| **Traditional server** | No special env vars | Starts `net/http` server on `:8080` |
| **WAGI (Spin/Wasm)** | `REQUEST_METHOD` env var present | Writes HTTP headers + body to stdout (CGI style), then exits |

Spin sets CGI-like environment variables. The program checks for `REQUEST_METHOD` to switch to WAGI mode, otherwise falls back to normal HTTP server. CLI mode overrides both. No SDK needed.

---

## Task 2 — Build Traditional Docker Container

- [x] Binary size from `ls -lh moscow-time-traditional`
- [x] Image size from both `docker images` and `docker image inspect`
- [x] Average startup time across 5 CLI mode runs
- [x] Memory usage from `docker stats` (MEM USAGE column)
- [x] Screenshot of application running in browser (server mode)

### 2.1 Review the Provided Dockerfile

1. **Examine the provided `Dockerfile`:**

   The `Dockerfile` is already in `labs/lab12/Dockerfile`. Review its contents:

   - **Build stage:** Uses `golang:1.21-alpine` to compile the Go binary
   - **Optimization flags:** `-tags netgo -trimpath -ldflags="-s -w -extldflags=-static"` for minimal size
   - **Run stage:** Uses `FROM scratch` (truly empty base image) for smallest possible image
   - **Static binary:** No external dependencies, fully self-contained

   > **Note:** We use `FROM scratch` (truly empty base image) instead of Alpine for the fairest comparison with WASM containers. The optimization flags produce a minimal, fully static binary with no external dependencies.

### 2.2 Build and Run Traditional Container

1. **Ensure you're in the lab directory:**

```bash
kamilya@Kama:/mnt/d/Programs/DevOps-Intro$ cd labs/lab12
```

2. **Clean up any previous containers (optional but recommended):**

```bash
kamilya@Kama:/mnt/d/Programs/DevOps-Intro/labs/lab12$ docker rm -f test-traditional test-wasm 2>/dev/null || true
kamilya@Kama:/mnt/d/Programs/DevOps-Intro/labs/lab12$ docker image prune -f 2>/dev/null || true
Deleted Images:
untagged: sha256:83171ce27ee204c737d6341002e655df6b38fd17e7c144d76c75a249f05b2335
deleted: sha256:83171ce27ee204c737d6341002e655df6b38fd17e7c144d76c75a249f05b2335
deleted: sha256:9cb6c8f57f8b87376db0ec760e181d9a98473c4a152275b25c7e693d78358be6
deleted: sha256:c558a40e0a3e51de18d4e756a4735d260eb8372540e388ad80d8cc17cd58d5e9

Total reclaimed space: 12.58kB
```

3. **Build Container:**

```bash
kamilya@Kama:/mnt/d/Programs/DevOps-Intro/labs/lab12$ docker build -t moscow-time-traditional -f Dockerfile .
[+] Building 18.7s (11/11) FINISHED                                                                                                                          docker:default
 => [internal] load build definition from Dockerfile                                                                                                                   0.1s
 ...
 => => naming to docker.io/library/moscow-time-traditional:latest                                                                                                      0.0s
 => => unpacking to docker.io/library/moscow-time-traditional:latest  
```

4. **Test CLI Mode:**

```bash
kamilya@Kama:/mnt/d/Programs/DevOps-Intro/labs/lab12$ docker run --rm -e MODE=once moscow-time-traditional
{
  "moscow_time": "2026-04-21 17:43:37 MSK",
  "timestamp": 1776782617
}
```

5. **Test Server Mode (Optional):**

```bash
kamilya@Kama:/mnt/d/Programs/DevOps-Intro/labs/lab12$ docker run --rm -p 8080:8080 moscow-time-traditional
2026/04/21 14:43:54 Server starting on :8080
```

   Test in browser: `http://localhost:8080`

### 2.3 Measure Performance

1. **Check Binary Size:**

```bash
# Extract and check binary size
kamilya@Kama:/mnt/d/Programs/DevOps-Intro/labs/lab12$ docker create --name temp-traditional moscow-time-traditional
776110025f115c57ac39104c96747519db58ffad00dc60d2211bc7f7cbc531e3

kamilya@Kama:/mnt/d/Programs/DevOps-Intro/labs/lab12$ docker cp temp-traditional:/app/moscow-time ./moscow-time-traditional

Successfully copied 4.7MB to /mnt/d/Programs/DevOps-Intro/labs/lab12/moscow-time-traditional

kamilya@Kama:/mnt/d/Programs/DevOps-Intro/labs/lab12$ docker rm temp-traditional
temp-traditional

kamilya@Kama:/mnt/d/Programs/DevOps-Intro/labs/lab12$ ls -lh moscow-time-traditional
-rwxrwxrwx 1 kamilya kamilya 4.5M Apr 21 17:41 moscow-time-traditional
```

2. **Check Image Size:**

```bash
kamilya@Kama:/mnt/d/Programs/DevOps-Intro/labs/lab12$ docker images moscow-time-traditional
REPOSITORY                TAG       IMAGE ID       CREATED          SIZE
moscow-time-traditional   latest    67b107d70d63   18 minutes ago   6.79MB

# More precise size measurement
kamilya@Kama:/mnt/d/Programs/DevOps-Intro/labs/lab12$ docker image inspect moscow-time-traditional --format '{{.Size}}' | awk '{print $1/1024/1024 " MB"}'
1.97717 MB
```

3. **Startup Time Benchmark (CLI Mode):**

```bash
# Compute average automatically
kamilya@Kama:/mnt/d/Programs/DevOps-Intro/labs/lab12$ for i in {1..5}; do
    /usr/bin/time -f "%e" docker run --rm -e MODE=once moscow-time-traditional 2>&1 | tail -n 1
done | awk '{sum+=$1; count++} END {print "Average:", sum/count, "seconds"}'
Average: 0.684 seconds
```

4. **Memory Usage (Server Mode):**

In one terminal:
```bash
kamilya@Kama:/mnt/d/Programs/DevOps-Intro/labs/lab12$ docker run --rm --name test-traditional -p 8080:8080 moscow-time-traditional
2026/04/21 15:01:41 Server starting on :8080
```

In another terminal:
```bash
kamilya@Kama:/mnt/d/Programs/DevOps-Intro/labs/lab12$ docker stats test-traditional --no-stream
CONTAINER ID   NAME               CPU %     MEM USAGE / LIMIT    MEM %     NET I/O         BLOCK I/O   PIDS
e2c8a19d5b53   test-traditional   0.00%     1.551MiB / 7.62GiB   0.02%     1.17kB / 126B   0B / 0B     5
```
   
![alt text](screenshots/image-1.png)
![alt text](screenshots/image-2.png)


---

## Task 3 — Build WASM Container (ctr-based)

- [x] TinyGo version used
- [x] WASM binary size (from `ls -lh main.wasm`)
- [x] WASI image size (from `ctr images ls`)
- [x] Average startup time from the `ctr run` benchmark loop (CLI mode)
- [x] Explanation of why server mode doesn't work under `ctr` (WASI Preview1 lacks socket support)
- [x] Note that server mode **can** be demonstrated via Spin using the same `main.wasm`
- [x] Memory usage reporting (likely "N/A" with explanation)
- [x] Note: used **same source code** as traditional build
- [x] Confirmation that you used `ctr` (containerd CLI) for WASM execution

### 3.1 Capture TinyGo Version

1. **Record Build Environment:**

```bash
kamilya@Kama:/mnt/d/Programs/DevOps-Intro/labs/lab12$ docker run --rm tinygo/tinygo:0.39.0 tinygo version
Unable to find image 'tinygo/tinygo:0.39.0' locally
0.39.0: Pulling from tinygo/tinygo
c16f92da8352: Pull complete 
edc4524582c1: Pull complete 
112172c80402: Pull complete 
a176e908aeb8: Pull complete 
7e48f4a80fb4: Pull complete 
4f4fb700ef54: Pull complete 
cd48a6f0da32: Pull complete 
Digest: sha256:0e51d243c1b84ec650f2dcd1cce3a09bb09730e1134771aeace2240ade4b32f5
Status: Downloaded newer image for tinygo/tinygo:0.39.0
tinygo version 0.39.0 linux/amd64 (using go version go1.25.0 and LLVM version 19.1.2)
```

### 3.2 Build WASM Binary Using TinyGo

1. **Ensure you're in the lab directory:**

```bash
kamilya@Kama:/mnt/d/Programs/DevOps-Intro$ cd labs/lab12
```

2. **Compile to WASM:**

```bash
# Linux/macOS:
kamilya@Kama:/mnt/d/Programs/DevOps-Intro/labs/lab12$ docker run --rm \
    -v $(pwd):/src \
    -w /src \
    tinygo/tinygo:0.39.0 \
    tinygo build -o main.wasm -target=wasi main.go
```

3. **Verify WASM Binary:**

```bash
kamilya@Kama:/mnt/d/Programs/DevOps-Intro/labs/lab12$ ls -lh main.wasm
-rwxrwxrwx 1 kamilya kamilya 2.4M Apr 21 18:09 main.wasm
kamilya@Kama:/mnt/d/Programs/DevOps-Intro/labs/lab12$ file main.wasm
main.wasm: WebAssembly (wasm) binary module version 0x1 (MVP)
```

### 3.3 Review the WASM Dockerfile

1. **Examine the provided `Dockerfile.wasm`:**

   The `Dockerfile.wasm` is already in `labs/lab12/Dockerfile.wasm`. Review its contents:

   - **Base image:** `FROM scratch` (empty base, same as traditional Dockerfile)
   - **Content:** Only copies the `main.wasm` binary
   - **Entry point:** Directly executes the WASM module
   - **Size:** Extremely minimal - just the WASM binary plus minimal OCI metadata

   > **Note:** This is a WASI module. The `EXPOSE` directive is informational only and doesn't enable networking. The actual runtime (wasmtime shim) handles WASM execution.

### 3.4 Build and Run WASM Container

**Install and Verify Prerequisites:**

Before building, ensure your environment is ready:

1. **Install containerd (if not already installed):**

```bash
# For Ubuntu/Debian
kamilya@Kama:/mnt/d/Programs/DevOps-Intro/labs/lab12$ sudo apt-get update
[sudo] password for kamilya: 
Hit:1 http://archive.ubuntu.com/ubuntu jammy InRelease
Get:2 http://security.ubuntu.com/ubuntu jammy-security InRelease [129 kB]
Get:3 http://archive.ubuntu.com/ubuntu jammy-updates InRelease [128 kB]
Get:4 http://archive.ubuntu.com/ubuntu jammy-backports InRelease [127 kB]
Get:5 http://security.ubuntu.com/ubuntu jammy-security/main amd64 Packages [3146 kB]
Get:6 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 Packages [3410 kB]
Get:7 http://archive.ubuntu.com/ubuntu jammy-updates/main Translation-en [519 kB]                                                                                          
Get:8 http://security.ubuntu.com/ubuntu jammy-security/main Translation-en [448 kB]                                                                                        
Get:9 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 c-n-f Metadata [19.6 kB]                                                                                   
Get:10 http://archive.ubuntu.com/ubuntu jammy-updates/restricted amd64 Packages [5713 kB]                                                                                  
Get:11 http://security.ubuntu.com/ubuntu jammy-security/main amd64 c-n-f Metadata [14.1 kB]                                                                                
Get:12 http://security.ubuntu.com/ubuntu jammy-security/restricted amd64 Packages [5544 kB]                                                                                
Get:13 http://security.ubuntu.com/ubuntu jammy-security/restricted Translation-en [1066 kB]                                                                                
Get:14 http://security.ubuntu.com/ubuntu jammy-security/restricted amd64 c-n-f Metadata [680 B]                                                                            
Get:15 http://security.ubuntu.com/ubuntu jammy-security/universe amd64 Packages [1025 kB]                                                                                  
Get:16 http://archive.ubuntu.com/ubuntu jammy-updates/restricted Translation-en [1097 kB]                                                                                  
Get:17 http://security.ubuntu.com/ubuntu jammy-security/universe Translation-en [226 kB]                                                                                   
Get:18 http://security.ubuntu.com/ubuntu jammy-security/universe amd64 c-n-f Metadata [22.8 kB]                                                                            
Get:19 http://security.ubuntu.com/ubuntu jammy-security/multiverse amd64 Packages [51.9 kB]                                                                                
Get:20 http://security.ubuntu.com/ubuntu jammy-security/multiverse Translation-en [10.6 kB]                                                                                
Get:21 http://security.ubuntu.com/ubuntu jammy-security/multiverse amd64 c-n-f Metadata [388 B]                                                                            
Get:22 http://archive.ubuntu.com/ubuntu jammy-updates/restricted amd64 c-n-f Metadata [676 B]                                                                              
Get:23 http://archive.ubuntu.com/ubuntu jammy-updates/universe amd64 Packages [1262 kB]                                                                                    
Get:24 http://archive.ubuntu.com/ubuntu jammy-updates/universe Translation-en [316 kB]                                                                                     
Get:25 http://archive.ubuntu.com/ubuntu jammy-updates/universe amd64 c-n-f Metadata [30.5 kB]                                                                              
Get:26 http://archive.ubuntu.com/ubuntu jammy-updates/multiverse amd64 Packages [59.0 kB]                                                                                  
Get:27 http://archive.ubuntu.com/ubuntu jammy-updates/multiverse Translation-en [13.5 kB]                                                                                  
Get:28 http://archive.ubuntu.com/ubuntu jammy-updates/multiverse amd64 c-n-f Metadata [612 B]                                                                              
Get:29 http://archive.ubuntu.com/ubuntu jammy-backports/main amd64 Packages [69.4 kB]                                                                                      
Get:30 http://archive.ubuntu.com/ubuntu jammy-backports/main amd64 c-n-f Metadata [412 B]                                                                                  
Get:31 http://archive.ubuntu.com/ubuntu jammy-backports/universe amd64 Packages [30.6 kB]                                                                                  
Get:32 http://archive.ubuntu.com/ubuntu jammy-backports/universe Translation-en [16.9 kB]                                                                                  
Get:33 http://archive.ubuntu.com/ubuntu jammy-backports/universe amd64 c-n-f Metadata [676 B]                                                                              
Fetched 24.5 MB in 47s (523 kB/s)                                                                                                                                          
Reading package lists... Done
kamilya@Kama:/mnt/d/Programs/DevOps-Intro/labs/lab12$ sudo apt-get install -y containerd
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
The following additional packages will be installed:
  runc
The following NEW packages will be installed:
  containerd runc
0 upgraded, 2 newly installed, 0 to remove and 163 not upgraded.
Need to get 37.8 MB of archives.
After this operation, 140 MB of additional disk space will be used.
Get:1 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 runc amd64 1.3.4-0ubuntu1~22.04.1 [9569 kB]
Get:2 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 containerd amd64 2.2.1-0ubuntu1~22.04.1 [28.2 MB]
Fetched 37.8 MB in 2s (18.0 MB/s)     
Selecting previously unselected package runc.
(Reading database ... 32191 files and directories currently installed.)
Preparing to unpack .../runc_1.3.4-0ubuntu1~22.04.1_amd64.deb ...
Unpacking runc (1.3.4-0ubuntu1~22.04.1) ...
Selecting previously unselected package containerd.
Preparing to unpack .../containerd_2.2.1-0ubuntu1~22.04.1_amd64.deb ...
Unpacking containerd (2.2.1-0ubuntu1~22.04.1) ...
Setting up runc (1.3.4-0ubuntu1~22.04.1) ...
Setting up containerd (2.2.1-0ubuntu1~22.04.1) ...
Created symlink /etc/systemd/system/multi-user.target.wants/containerd.service → /lib/systemd/system/containerd.service.
Processing triggers for man-db (2.10.2-1) ...

# Start and enable containerd
kamilya@Kama:/mnt/d/Programs/DevOps-Intro/labs/lab12$ sudo systemctl enable --now containerd
kamilya@Kama:/mnt/d/Programs/DevOps-Intro/labs/lab12$ sudo systemctl status containerd
● containerd.service - containerd container runtime
     Loaded: loaded (/lib/systemd/system/containerd.service; enabled; vendor preset: enabled)
     Active: active (running) since Tue 2026-04-21 18:13:00 MSK; 20s ago
       Docs: https://containerd.io
   Main PID: 16693 (containerd)
      Tasks: 11
     Memory: 14.7M
        CPU: 168ms
     CGroup: /system.slice/containerd.service
             └─16693 /usr/bin/containerd

Apr 21 18:13:00 Kama containerd[16693]: time="2026-04-21T18:13:00.219416474+03:00" level=info msg="Start cni network conf syncer for default"
Apr 21 18:13:00 Kama containerd[16693]: time="2026-04-21T18:13:00.219424053+03:00" level=info msg="Start streaming server"
Apr 21 18:13:00 Kama containerd[16693]: time="2026-04-21T18:13:00.219432971+03:00" level=info msg="Registered namespace \"k8s.io\" with NRI"
Apr 21 18:13:00 Kama containerd[16693]: time="2026-04-21T18:13:00.219442128+03:00" level=info msg="runtime interface starting up..."
Apr 21 18:13:00 Kama containerd[16693]: time="2026-04-21T18:13:00.219447010+03:00" level=info msg="starting plugins..."
Apr 21 18:13:00 Kama containerd[16693]: time="2026-04-21T18:13:00.219461817+03:00" level=info msg="Synchronizing NRI (plugin) with current runtime state"
Apr 21 18:13:00 Kama containerd[16693]: time="2026-04-21T18:13:00.219621896+03:00" level=info msg=serving... address=/run/containerd/containerd.sock.ttrpc
Apr 21 18:13:00 Kama containerd[16693]: time="2026-04-21T18:13:00.219671142+03:00" level=info msg=serving... address=/run/containerd/containerd.sock
Apr 21 18:13:00 Kama containerd[16693]: time="2026-04-21T18:13:00.219788637+03:00" level=info msg="containerd successfully booted in 0.061354s"
Apr 21 18:13:00 Kama systemd[1]: Started containerd container runtime.
# Should show "active (running)"
```

2. **Verify ctr is available:**

```bash
# ctr comes bundled with containerd
kamilya@Kama:/mnt/d/Programs/DevOps-Intro/labs/lab12$ ctr --version
ctr github.com/containerd/containerd/v2 2.2.1
```

   You should see output like: `ctr containerd.io 1.x.x`

3. **Install the Wasmtime runtime shim:**

   We'll **build the shim from source using Docker** (no Rust installation needed!):

```bash
# Build the wasmtime shim using Docker (takes ~5-10 minutes)
kamilya@Kama:/mnt/d/Programs/DevOps-Intro/labs/lab12$ docker run --rm \
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
    rm -rf runwasi
    git clone --depth 1 https://github.com/containerd/runwasi.git
    cd runwasi

    echo "[4/5] Build Wasmtime shim (release)"
    cargo build --release -p containerd-shim-wasmtime

    echo "[5/5] Copy binary to host"
    install -m 0755 target/release/containerd-shim-wasmtime-v1 /out/
'
# Really long output...

# Install the shim to /usr/local/bin
kamilya@Kama:/mnt/d/Programs/DevOps-Intro/labs/lab12$ sudo install -D -m0755 containerd-shim-wasmtime-v1 /usr/local/bin/
[sudo] password for kamilya:

# Verify installation
kamilya@Kama:/mnt/d/Programs/DevOps-Intro/labs/lab12$ ls -la /usr/local/bin/containerd-shim-wasmtime-v1
-rwxr-xr-x 1 root root 32329576 Apr 21 18:33 /usr/local/bin/containerd-shim-wasmtime-v1
```

   > **Why Docker?** This approach avoids installing Rust toolchain on your host system. The container handles all build dependencies (Rust, Cargo, libseccomp, protobuf, etc.) automatically, and outputs only the compiled shim binary.

4. **Configure containerd to register the wasmtime shim:**

   > **Why configure containerd?** While `ctr` can use the shim binary directly, registering it in containerd's configuration ensures it's available for Kubernetes and other CRI clients. It's good practice for production environments.

```bash
# Backup existing config if present
kamilya@Kama:/mnt/d/Programs/DevOps-Intro/labs/lab12$ sudo cp /etc/containerd/config.toml /etc/containerd/config.toml.backup 2>/dev/null || true

# Generate default config if you don't have one
kamilya@Kama:/mnt/d/Programs/DevOps-Intro/labs/lab12$ sudo mkdir -p /etc/containerd
kamilya@Kama:/mnt/d/Programs/DevOps-Intro/labs/lab12$ containerd config default | sudo tee /etc/containerd/config.toml >/dev/null
```

   **Manually add the wasmtime runtime configuration:**

   Open the config file with your preferred editor:

```bash
kamilya@Kama:/mnt/d/Programs/DevOps-Intro/labs/lab12$ sudo nano /etc/containerd/config.toml
# or
sudo vim /etc/containerd/config.toml
```

   Find the section `[plugins.'io.containerd.cri.v1.runtime'.containerd.runtimes]`. You'll see the `runc` runtime configuration there. **Add the wasmtime runtime block right after the `runc` block** (as a sibling, at the same indentation level):

```toml
[plugins.'io.containerd.cri.v1.runtime'.containerd.runtimes]
    [plugins.'io.containerd.cri.v1.runtime'.containerd.runtimes.runc]
    runtime_type = 'io.containerd.runc.v2'
    runtime_path = ''
    # ... other runc config ...
    
    # ✅ Add this whole block:
    [plugins.'io.containerd.cri.v1.runtime'.containerd.runtimes.wasmtime]
        runtime_type = 'io.containerd.wasmtime.v1'
        [plugins.'io.containerd.cri.v1.runtime'.containerd.runtimes.wasmtime.options]
        BinaryName = '/usr/local/bin/containerd-shim-wasmtime-v1'
```

   **Key points:**
   - The `wasmtime` block should be at the same level as the `runc` block (both under `runtimes`)
   - Use the same indentation as the `runc` section
   - The `options` subsection is indented one more level
   - Save and exit (`Ctrl+O`, `Enter`, `Ctrl+X` for nano; `:wq` for vim)

   **Restart containerd and verify configuration:**

```bash
kamilya@Kama:/mnt/d/Programs/DevOps-Intro/labs/lab12$ sudo systemctl restart containerd
kamilya@Kama:/mnt/d/Programs/DevOps-Intro/labs/lab12$ sudo systemctl status containerd --no-pager
● containerd.service - containerd container runtime
     Loaded: loaded (/lib/systemd/system/containerd.service; enabled; vendor preset: enabled)
     Active: active (running) since Tue 2026-04-21 18:38:43 MSK; 10s ago
       Docs: https://containerd.io
    Process: 23072 ExecStartPre=/sbin/modprobe overlay (code=exited, status=0/SUCCESS)
   Main PID: 23073 (containerd)
      Tasks: 12
     Memory: 34.1M
        CPU: 163ms
     CGroup: /system.slice/containerd.service
             └─23073 /usr/bin/containerd

Apr 21 18:38:43 Kama containerd[23073]: time="2026-04-21T18:38:43.090377160+03:00" level=info msg=serving... address=/run/containerd/containerd.sock
Apr 21 18:38:43 Kama containerd[23073]: time="2026-04-21T18:38:43.092216406+03:00" level=info msg="Start event monitor"
Apr 21 18:38:43 Kama containerd[23073]: time="2026-04-21T18:38:43.092347187+03:00" level=info msg="Start cni network conf syncer for default"
Apr 21 18:38:43 Kama containerd[23073]: time="2026-04-21T18:38:43.092361965+03:00" level=info msg="Start streaming server"
Apr 21 18:38:43 Kama containerd[23073]: time="2026-04-21T18:38:43.092426312+03:00" level=info msg="Registered namespace \"k8s.io\" with NRI"
Apr 21 18:38:43 Kama containerd[23073]: time="2026-04-21T18:38:43.092712420+03:00" level=info msg="runtime interface starting up..."
Apr 21 18:38:43 Kama containerd[23073]: time="2026-04-21T18:38:43.092730675+03:00" level=info msg="starting plugins..."
Apr 21 18:38:43 Kama containerd[23073]: time="2026-04-21T18:38:43.092753209+03:00" level=info msg="Synchronizing NRI (plugin) with current runtime state"
Apr 21 18:38:43 Kama containerd[23073]: time="2026-04-21T18:38:43.107969394+03:00" level=info msg="containerd successfully booted in 0.150344s"
Apr 21 18:38:43 Kama systemd[1]: Started containerd container runtime.
# Should show "active (running)"
```

   **Verify the wasmtime runtime is correctly registered:**

```bash
# Check the runtimes section in the active config
kamilya@Kama:/mnt/d/Programs/DevOps-Intro/labs/lab12$ sudo containerd config dump | sed -n "/io.containerd.cri.v1.runtime'.containerd/,/^\[/p" | sed -n '/runtimes/,+20p'
    [plugins.'io.containerd.cri.v1.runtime'.containerd.runtimes]
    [plugins.'io.containerd.cri.v1.runtime'.containerd.runtimes.runc]
        runtime_type = 'io.containerd.runc.v2'
        runtime_path = ''
        pod_annotations = []
        container_annotations = []
        privileged_without_host_devices = false
        privileged_without_host_devices_all_devices_allowed = false
        cgroup_writable = false
        base_runtime_spec = ''
        cni_conf_dir = ''
        cni_max_conf_num = 0
        snapshotter = ''
        sandboxer = 'podsandbox'
        io_type = ''

        [plugins.'io.containerd.cri.v1.runtime'.containerd.runtimes.runc.options]
        BinaryName = ''
        CriuImagePath = ''
        CriuWorkPath = ''
        IoGid = 0
    [plugins.'io.containerd.cri.v1.runtime'.containerd.runtimes.wasmtime]
        runtime_type = 'io.containerd.wasmtime.v1'
        runtime_path = ''
        pod_annotations = []
        container_annotations = []
        privileged_without_host_devices = false
        privileged_without_host_devices_all_devices_allowed = false
        cgroup_writable = false
        base_runtime_spec = ''
        cni_conf_dir = ''
        cni_max_conf_num = 0
        snapshotter = ''
        sandboxer = ''
        io_type = ''

        [plugins.'io.containerd.cri.v1.runtime'.containerd.runtimes.wasmtime.options]
        BinaryName = '/usr/local/bin/containerd-shim-wasmtime-v1'

[plugins.'io.containerd.cri.v1.runtime'.cni]
    bin_dir = ''
    bin_dirs = ['/opt/cni/bin']
```

   You should see both `runc` and `wasmtime` runtimes listed, with the wasmtime section showing:
```toml
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.wasmtime]
    runtime_type = "io.containerd.wasmtime.v1"
    ...
```

   > **Note:** If the wasmtime section doesn't appear, check your TOML indentation and hierarchy in `/etc/containerd/config.toml`. The wasmtime block should be at the same level as the runc block under the runtimes section.

5. **Final verification:**

```bash
# Check that wasmtime shim is in the correct location
kamilya@Kama:/mnt/d/Programs/DevOps-Intro/labs/lab12$ ls -la /usr/local/bin/containerd-shim-wasmtime-v1
-rwxr-xr-x 1 root root 32329576 Apr 21 18:33 /usr/local/bin/containerd-shim-wasmtime-v1

# Verify containerd is running
kamilya@Kama:/mnt/d/Programs/DevOps-Intro/labs/lab12$ sudo ctr version
Client:
  Version:  2.2.1
  Revision: 
  Go version: go1.24.4

Server:
  Version:  2.2.1
  Revision: 
  UUID: 58f89628-d690-4a9f-96e6-7d016b09e9e7
```

**Build OCI Archive and Import into containerd:**

1. **Build WASI image to OCI archive using Docker Buildx:**

```bash
kamilya@Kama:/mnt/d/Programs/DevOps-Intro/labs/lab12$ docker buildx build \
    --platform=wasi/wasm \
    -t moscow-time-wasm:latest \
    -f Dockerfile.wasm \
    --output=type=oci,dest=moscow-time-wasm.oci,annotation=index:org.opencontainers.image.ref.name=moscow-time-wasm:latest \
    .
[+] Building 0.7s (5/5) FINISHED                                                                                                                             docker:default
 => [internal] load build definition from Dockerfile.wasm                                                                                                              0.1s
 => => transferring dockerfile: 121B                                                                                                                                   0.0s
 => [internal] load .dockerignore                                                                                                                                      0.0s
 => => transferring context: 2B                                                                                                                                        0.0s
 => [internal] load build context                                                                                                                                      0.1s
 => => transferring context: 2.45MB                                                                                                                                    0.1s
 => [1/1] COPY main.wasm /main.wasm                                                                                                                                    0.0s
 => exporting to oci image format                                                                                                                                      0.3s
 => => exporting layers                                                                                                                                                0.2s
 => => exporting manifest sha256:d639072f0544c6e17d485da8e26a1ae7ebaa40e76491d7ed10b551efb2a91b62                                                                      0.0s
 => => exporting config sha256:fa94a49094b759d1a46d6b5f89d3f420c3123dd9728dbb38e902f93e03c0707c                                                                        0.0s
 => => sending tarball   
```

   > **What this does:** Docker Buildx builds for the `wasi/wasm` platform and creates an OCI-compliant image archive. This archive can be imported into any OCI-compatible image store, including containerd.

2. **Import the OCI archive into containerd:**

```bash
kamilya@Kama:/mnt/d/Programs/DevOps-Intro/labs/lab12$ sudo ctr images import \
    --platform=wasi/wasm \
    --index-name docker.io/library/moscow-time-wasm:latest \
    moscow-time-wasm.oci
docker.io/library/moscow time wasm:lates        saved
application/vnd.oci.image.manifest.v1+json sha256:d639072f0544c6e17d485da8e26a1ae7ebaa40e76491d7ed10b551efb2a91b62
Importing       elapsed: 0.2 s  total:   0.0 B  (0.0 B/s)
```

3. **Verify the image was imported:**

```bash
kamilya@Kama:/mnt/d/Programs/DevOps-Intro/labs/lab12$ sudo ctr images ls | grep -E 'moscow-time-wasm|wasi|wasm'
docker.io/library/moscow-time-wasm:latest application/vnd.oci.image.manifest.v1+json sha256:d639072f0544c6e17d485da8e26a1ae7ebaa40e76491d7ed10b551efb2a91b62 819.9 KiB wasi/wasm -    
```

   You should see: `docker.io/library/moscow-time-wasm:latest`

**Run WASM Container with ctr:**

1. **Test CLI Mode (one-shot run):**

```bash
kamilya@Kama:/mnt/d/Programs/DevOps-Intro/labs/lab12$ sudo ctr run --rm \
    --runtime io.containerd.wasmtime.v1 \
    --platform wasi/wasm \
    --env MODE=once \
    docker.io/library/moscow-time-wasm:latest wasi-once
{
  "moscow_time": "2026-04-21 18:43:24 MSK",
  "timestamp": 1776786204
}
```

   > **Note:** The final argument (`wasi-once`) is a unique container name required by `ctr`.

2. **Server Mode Limitation:**

   **Plain WASI (Preview1) modules do not support TCP sockets.** Server mode under `ctr` is not supported for the standard `main.wasm` you just built, because WASI Preview1 lacks networking capabilities.

   If you try to run without `MODE=once`, you'll see:
   ```
   Server starting on :8080
   Netdev not set
   ```

   The TinyGo `net/http` library attempts to open a socket, but the WASI runtime has no "netdev" to provide, so nothing binds.

   **For server mode, use Spin (Bonus Task)** with the **same `main.wasm`** (no rebuild needed!):
   - `spin up` → test at `http://localhost:3000`
   - Spin provides the HTTP server and uses CGI-style environment variables
   - Your `main.go` already handles WAGI mode via the `isWagi()` and `runWagiOnce()` functions
   - Same binary, different execution context ✅

### 3.5 Measure WASM Performance

1. **Check Sizes:**

```bash
# Binary size
kamilya@Kama:/mnt/d/Programs/DevOps-Intro/labs/lab12$ ls -lh main.wasm
-rwxrwxrwx 1 kamilya kamilya 2.4M Apr 21 18:09 main.wasm

# Image size (ctr images ls)
kamilya@Kama:/mnt/d/Programs/DevOps-Intro/labs/lab12$ sudo ctr images ls | awk 'NR>1 && $1 ~ /moscow-time-wasm/ {print "IMAGE:", $1, "SIZE:", $4}'
IMAGE: docker.io/library/moscow-time-wasm:latest SIZE: 819.9
```

2. **Startup Time Benchmark (CLI Mode with unique names):**

   > **Important:** `ctr run` requires unique container names for each invocation. We generate unique names using timestamps.

```bash
kamilya@Kama:/mnt/d/Programs/DevOps-Intro/labs/lab12$ for i in {1..5}; do
    NAME="wasi-$(date +%s%N | tail -c 6)-$i"
    /usr/bin/time -f "%e" sudo ctr run --rm \
        --runtime io.containerd.wasmtime.v1 \
        --platform wasi/wasm \
        --env MODE=once \
        docker.io/library/moscow-time-wasm:latest "$NAME" 2>&1 | tail -n 1
done | awk '{sum+=$1; n++} END{printf("Average: %.4f seconds\n", sum/n)}'
Average: 0.5480 seconds
```

3. **Memory Usage:**

   Memory reporting for WASM containers via `ctr` is typically not available. WASM runs in a sandboxed runtime with different resource accounting mechanisms than traditional Linux containers. 
   
   **What to document:** State "N/A - not available via ctr" and explain that WASM uses a different execution model. The wasmtime runtime manages WASM memory internally, and traditional container metrics (cgroups) don't apply.


### 3.6 Why server mode doesn't work under `ctr`

**WASI Preview1 has no socket support.** The WebAssembly System Interface (WASI) Preview1 specification does not include networking APIs (TCP/UDP sockets). When the `main.go` program runs under `ctr` with the `wasmtime` shim, it detects neither `MODE=once` (CLI) nor the `REQUEST_METHOD` env var (Spin's WAGI mode). It therefore falls back to traditional server mode, attempting to call `http.ListenAndServe(":8080", nil)`. This requires opening a TCP socket, but the WASI runtime provides no `socket`, `bind`, `listen`, or `accept` system calls. The result is an error like `Netdev not set` or a silent failure—the server never starts.

**Contrast with Spin:** Spin provides a host-side HTTP server and communicates with the Wasm module via the WAGI protocol (stdin/stdout + env vars), not by exposing raw sockets to the Wasm guest. That’s why the same binary works in Spin but not under plain `ctr` + wasmtime.




---

## Task 4 — Performance Comparison & Analysis

- [x] Complete comparison table with all metrics
- [x] Calculated improvement percentages
- [x] Detailed answers to all questions
- [x] Recommendations for when to use each approach

**Objective:** Analyze and compare the performance characteristics of traditional vs WASM containers built from the **same source code**.

### 4.1 Create Comprehensive Comparison Table

| Metric | Traditional Container | WASM Container | Improvement | Notes |
|--------|----------------------|----------------|-------------|-------|
| **Binary Size** | 4.5 MB | 2.4 MB | 47% smaller | `ls -lh` of extracted binary (traditional) vs `main.wasm` |
| **Image Size** | 6.79 MB | 0.82 MB | 88% smaller | Compressed OCI image size – WASM image is extremely lea |
| **Startup Time (CLI)** | 684 ms | 548 ms | 1.25x faster | Average of 5 runs |
| **Memory Usage** | 1.55 MB | N/A (not reported by `ctr`) | - | WASM memory managed by runtime, no cgroup metrics |
| **Base Image** | scratch | scratch | Same | Both minimal |
| **Source Code** | main.go | main.go | Identical | ✅ Same file! |
| **Server Mode** | ✅ Works (net/http) | ❌ Not via ctr <br> ✅ Via Spin (WAGI) | N/A | WASI Preview1 lacks sockets; <br> Spin provides HTTP abstraction |


**Improvement calculations:**
- **Binary size reduction:** `(4.5 - 2.4) / 4.5 × 100 = 46.7%`
- **Image size reduction:** `(6.79 - 0.82) / 6.79 × 100 = 87.9%`
- **Startup speedup factor:** `684 / 548 = 1.25x`

### 4.2 Analysis Questions

Answer the following in your submission:

1. **Binary Size Comparison:**
   - Why is the WASM binary so much smaller than the traditional Go binary?
   - What did TinyGo optimize away?  

   TinyGo uses LLVM optimizations, removes full Go runtime (GC, scheduler), and strips dead code. Traditional Go binary includes runtime overhead even for simple programs.
   TinyGo removes/optimizes:
    - Full garbage collector → replaced with a simple allocator
    - Goroutine preemption & scheduler → limited to cooperative scheduling
    - Large runtime maps and type information → only what’s used
    - Debug symbols and DWARF info (unless explicitly requested)
    - Standard library functions that are not reachable (dead code elimination)

2. **Startup Performance:**
   - Why does WASM start faster?
   - What initialization overhead exists in traditional containers?

   WASM starts about 25% faster (684 ms vs 548 ms). The difference becomes even more pronounced at scale (cold starts).

   WASM avoids namespace/cgroup setup, rootfs unpacking, and networking creation. The wasmtime shim compiles bytecode quickly to native code. 
   
   WASM containers are ideal for short‑lived, event‑driven workloads (e.g., serverless functions, API gateways) where cold start latency matters.

3. **Use Case Decision Matrix:**
   - When would you choose WASM over traditional containers?
   - When would you stick with traditional containers?

   **WASM:** serverless, edge, low‑resource, short‑lived tasks, strong isolation.  
   **Traditional:** long‑running services, full OS access, complex networking, mature tooling.
4. **Recommendation**
    Start with traditional containers for general‑purpose services. Use WASM for:
    - Functions as a Service (FaaS) – e.g., AWS Lambda (now supports WASM via extensions), Fermyon Spin, wasmCloud.
    - Sidecar proxies or filters – Envoy’s WebAssembly extensions.
    - Untrusted user code – WASM’s capability‑based security is stronger than seccomp‑namespaced containers.

    Both approaches can coexist: orchestrate WASM modules with Spin or runwasi inside Kubernetes, and traditional containers for the rest of your stack.

---

## Bonus Task — Deploy to Fermyon Spin Cloud

- [x] Public URL of your deployed application (`$SPIN_URL`)
- [x] Deployment time from `spin deploy` command output
- [x] **Cold start measurements:**
  - Calculated average cold start time
- [x] **Warm measurements:**
  - Calculated average warm time
  - Comparison with cold start times
- [x] **Local Spin measurements:**
  - Calculated average local time
  - Comparison with cloud deployment
- [x] **Reflection:**
  - Would you use Spin for production workloads? Why or why not?
  - How does this compare to traditional serverless (AWS Lambda, Cloud Functions)?

**Objective:** Deploy your WASM application to Fermyon Spin Cloud for serverless edge hosting.

**Why This Matters:** Spin is a production-ready WASM serverless platform that showcases real-world WASM deployment with instant global distribution.

**🎯 Key Insight:** Your `main.go` already supports Spin! We'll use Spin's **WAGI executor** which runs your WASM in CGI mode—no SDK or code changes needed. The same file works for Docker (net/http), WASM containers (CLI mode), and Spin (WAGI mode).

### B.1 Install Spin CLI

<details>
<summary>💻 Installation Commands</summary>

**Linux/macOS:**
```bash
kamilya@Kama:/mnt/d/Programs/DevOps-Intro/labs/lab12$ curl -fsSL https://developer.fermyon.com/downloads/install.sh | bash
Step 1: Downloading: https://github.com/spinframework/spin/releases/download/v4.0.0/spin-v4.0.0-linux-amd64.tar.gz
Done...

Step 2: Decompressing: spin-v4.0.0-linux-amd64.tar.gz
crt.pem
spin.sig
README.md
LICENSE
spin
spin 4.0.0 (5f3aa19 2026-04-20)
Done...

Step 3: Removing the downloaded tarball
Done...

Step 4: Installing default templates
Copying remote template source
Installing template http-rust...
Installing template redirect...
Installing template http-zig...
Installing template redis-rust...
Installing template static-fileserver...
Installing template http-empty...
Installing template http-c...
Installing template http-go...
Installing template redis-go...
Installing template http-php...
Installing template http-grain...
Installed 11 template(s)

+------------------------------------------------------------------------+
| Name                Description                                        |
+========================================================================+
| http-c              HTTP request handler using C and the Zig toolchain |
| http-empty          HTTP application with no components                |
| http-go             HTTP request handler using (Tiny)Go                |
| http-grain          HTTP request handler using Grain                   |
| http-php            HTTP request handler using PHP                     |
| http-rust           HTTP request handler using Rust                    |
| http-zig            HTTP request handler using Zig                     |
| redirect            Redirects a HTTP route                             |
| redis-go            Redis message handler using (Tiny)Go               |
| redis-rust          Redis message handler using Rust                   |
| static-fileserver   Serves static files from an asset directory        |
+------------------------------------------------------------------------+
Copying remote template source
Installing template http-py...
Installed 1 template(s)

+---------------------------------------------+
| Name      Description                       |
+=============================================+
| http-py   HTTP request handler using Python |
+---------------------------------------------+
Copying remote template source
Installing template http-js...
Installing template http-ts...
Installing template redis-ts...
Installing template redis-js...
Installed 4 template(s)

+---------------------------------------------------+
| Name       Description                            |
+===================================================+
| http-js    HTTP request handler using JavaScript  |
| http-ts    HTTP request handler using TypeScript  |
| redis-js   Redis message handler using JavaScript |
| redis-ts   Redis message handler using TypeScript |
+---------------------------------------------------+
Step 5: Installing default plugins
Plugin information updated successfully
Plugin 'cloud' was installed successfully!

Description:
        Commands for publishing applications to the Fermyon Cloud.

Homepage:
        https://github.com/fermyon/cloud-plugin
You're good to go. Check here for the next steps: https://spinframework.dev/quickstart
Run './spin' to get started

kamilya@Kama:/mnt/d/Programs/DevOps-Intro/labs/lab12$ sudo mv spin /usr/local/bin/
[sudo] password for kamilya: 
```

Verify installation:
```bash
kamilya@Kama:/mnt/d/Programs/DevOps-Intro/labs/lab12$ spin --version
spin 4.0.0 (5f3aa19 2026-04-20)
```

</details>

### B.2 Review Spin Configuration (WAGI Mode)

1. **Examine the provided `spin.toml`:**

   The configuration file is already in `labs/lab12/spin.toml`.

   **Key Configuration Details:**
   
   - `executor = { type = "wagi" }` tells Spin to use WAGI mode (CGI-style execution)
   - Spin sets environment variables like `REQUEST_METHOD` and `PATH_INFO`
   - Your program reads these vars, prints HTTP headers to STDOUT, then prints the response body
   - No Spin SDK needed—pure Go standard library!

   > **Why WAGI?** WAGI (WebAssembly Gateway Interface) is a CGI-style protocol. Spin starts your WASM per request, sets env vars, and expects an HTTP response on STDOUT. This lets us use the **same `main.go`** across all platforms!

### B.3 Prepare WASM Binary for Spin

> **Note:** If you completed Task 3, you already have `main.wasm` and can skip to B.4. The same binary works for both `ctr` and Spin!

<details>
<summary>🔄 Rebuild WASM binary (only if needed)</summary>

If you skipped Task 3 or need to rebuild:

1. **Ensure you're in the lab directory:**

   ```bash
   cd labs/lab12
   ```

2. **Build with TinyGo (same command as Task 3):**

   ```bash
   # Linux/macOS:
   docker run --rm \
       -v $(pwd):/src \
       -w /src \
       tinygo/tinygo:0.39.0 \
       tinygo build -o main.wasm -target=wasi main.go
   
   # Windows (PowerShell):
   docker run --rm \
       -v ${PWD}:/src \
       -w /src \
       tinygo/tinygo:0.39.0 \
       tinygo build -o main.wasm -target=wasi main.go
   ```

</details>

### B.4 Test Locally with Spin

1. **Verify you have the WASM binary:**

```bash
kamilya@Kama:/mnt/d/Programs/DevOps-Intro/labs/lab12$ ls -lh main.wasm
-rwxrwxrwx 1 kamilya kamilya 2.4M Apr 21 18:09 main.wasm
```

   You should see the `main.wasm` file from Task 3.

2. **Run Spin locally:**

```bash
kamilya@Kama:/mnt/d/Programs/DevOps-Intro/labs/lab12$ spin up
Logging component stdio to ".spin/logs/"

Serving http://127.0.0.1:3000
Available Routes:
  moscow-time: http://127.0.0.1:3000 (wildcard)
```

   Test at `http://localhost:3000`

   > **Note:** Spin will automatically use the existing `main.wasm`. The `spin build` command in `spin.toml` only runs if the binary is missing.

   <details>
   <summary>🔧 Troubleshooting</summary>

   **If Spin can't find the binary:**
   ```bash
   spin build
   ```

   **If TinyGo is not installed locally:**
   The `main.wasm` from Task 3 should work. If you need to rebuild, see B.3 above.

   </details>

### B.5 Deploy to Spin Cloud

1. **Sign Up for Fermyon Cloud:**

   Visit [https://cloud.fermyon.com](https://cloud.fermyon.com) and create a free account.

2. **Login via CLI:**

```bash
kamilya@Kama:/mnt/d/Programs/DevOps-Intro/labs/lab12$ spin cloud login

Copy your one-time code:

fj7iuRzV

...and open the authorization page in your browser:

https://cloud.fermyon.com/device-authorization

Waiting for device authorization...
Device authorized!
```

   > **Note:** Some installations use `spin cloud login` instead. If `spin login` fails, try:
   > ```bash
   > spin cloud login
   > ```

3. **Deploy Application:**

```bash
kamilya@Kama:/mnt/d/Programs/DevOps-Intro/labs/lab12$ spin cloud deploy
Uploading moscow-time version 1.0.0 to Fermyon Cloud...
Deploying...
Waiting for application to become ready...... ready

View application:   https://moscow-time-l1upz4gl.fermyon.app/
Manage application: https://cloud.fermyon.com/app/moscow-time
```

   Spin will provide a public URL like: `https://moscow-time-abc123.fermyon.app`

![alt text](screenshots/image-3.png)
![alt text](screenshots/image-4.png)

4. **Test Deployment:**

```bash
kamilya@Kama:/mnt/d/Programs/DevOps-Intro/labs/lab12$ curl https://moscow-time-l1upz4gl.fermyon.app/api/time
{"moscow_time":"2026-04-21 20:14:13 MSK","timestamp":1776791653}
```

### B.6 Measure and Compare Deployment Experience

1. **Measure deployment time:**

```bash
# Time the deployment
kamilya@Kama:/mnt/d/Programs/DevOps-Intro/labs/lab12$ time spin deploy
real    0m0.035s
user    0m0.010s
sys     0m0.061s
```

   Document:
   - Upload time (shown in Spin output)
   - Total deployment time (from `time` command)

2. **Measure cold start latency:**

   After deployment, measure response times. First, save your deployment URL:

```bash
# Replace with your actual Spin Cloud URL from the deployment output
kamilya@Kama:/mnt/d/Programs/DevOps-Intro/labs/lab12$ export SPIN_URL="https://moscow-time-l1upz4gl.fermyon.app/api/time"

# Verify it works
kamilya@Kama:/mnt/d/Programs/DevOps-Intro/labs/lab12$ curl -s "$SPIN_URL/api/time" | jq .
Command 'jq' not found, but can be installed with:
sudo snap install jq  # version 1.5+dfsg-1, or
sudo apt  install jq  # version 1.6-2.1ubuntu3.1
See 'snap info jq' for additional versions.
```

   **Calculate averages:**

```bash
# Cold start average
kamilya@Kama:/mnt/d/Programs/DevOps-Intro/labs/lab12$ echo "Cold start average:"
for i in {1..5}; do
    curl -sS -o /dev/null -w "%{time_total}\n" "$SPIN_URL/?_cold=$(date +%s%N)" 2>&1
    sleep 5
done | awk '{sum+=$1; n++} END {printf("Average: %.4f seconds\n", sum/n)}'
Cold start average:
Average: 1.7405 seconds

# Warm average
kamilya@Kama:/mnt/d/Programs/DevOps-Intro/labs/lab12$ echo "Warm average:"
for i in {1..5}; do
    curl -sS -o /dev/null -w "%{time_total}\n" "$SPIN_URL/api/time" 2>&1
    sleep 1
done | awk '{sum+=$1; n++} END {printf("Average: %.4f seconds\n", sum/n)}'
Warm average:
Average: 1.2161 seconds
```

   **Cold vs Warm:**
   - **Cold start**: Cache-busted request → forces new WASM instance at edge PoP
   - **Warm start**: Reuses running instance and/or CDN cache → much faster

   > **Note:** Your measurements will vary based on:
   > - Geographic distance to nearest Fastly PoP
   > - Network conditions and ISP routing
   > - CDN cache state
   > - Whether the specific edge PoP has a warm instance

3. **Measure local Spin startup (for comparison):**

   Local execution has no network overhead:

```bash
# Start Spin locally in background
kamilya@Kama:/mnt/d/Programs/DevOps-Intro/labs/lab12$ spin up & &
SPIN_PID=$!
sleep 2
[1] 49479
Logging component stdio to ".spin/logs/"

Serving http://127.0.0.1:3000
Available Routes:
  moscow-time: http://127.0.0.1:3000 (wildcard)

# Calculate average
kamilya@Kama:/mnt/d/Programs/DevOps-Intro/labs/lab12$ echo "Local average:"
for i in {1..5}; do
    curl -sS -o /dev/null -w "%{time_total}\n" "http://localhost:3000/api/time"
done | awk '{sum+=$1; n++} END {printf("Average: %.4f seconds\n", sum/n)}'
Local average:
Average: 0.0177 seconds

# Stop Spin
kamilya@Kama:/mnt/d/Programs/DevOps-Intro/labs/lab12$ kill $SPIN_PID
```

### B.7 Reflection
**Would you use Spin for production workloads? Why or why not?**

Yes, for HTTP-focused edge/serverless workloads – fast cold starts (~1.7s cloud, 18ms local), tiny binaries, global CDN. Avoid for complex networking or broad language/runtime needs.

**How does this compare to traditional serverless (AWS Lambda, Cloud Functions)?**

Spin has smaller binaries, faster edge deployment, built-in CDN, but fewer languages, no raw sockets, less mature tooling. Lambda is better for general-purpose, VPC, and complex integrations.
