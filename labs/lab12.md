# Lab 12 — WebAssembly Containers vs Traditional Containers

![difficulty](https://img.shields.io/badge/difficulty-advanced-red)
![topic](https://img.shields.io/badge/topic-WASM%20%26%20Containers-blue)
![points](https://img.shields.io/badge/points-10-orange)

> **Goal:** Build a Go web application and compare WebAssembly (WASM) containers with traditional Docker containers using the **same source code** compiled to different targets.  
> **Deliverable:** A PR from `feature/lab12` to the course repo with `labs/submission12.md` containing performance benchmarks, analysis, and comparison. Submit the PR link via Moodle.

---

## Overview

In this lab you will:
- Review a **Go HTTP web application** that works in both server and CLI modes.
- Build **traditional Docker containers** with standard Go compilation.
- Build **WASM containers** using TinyGo and run them with containerd's `ctr` CLI.
- Benchmark and compare **startup times, image sizes, and binary sizes** using the **same source code**.
- Understand why WASM containers have limitations (no TCP sockets in WASI Preview1).
- **Bonus:** Deploy to **Fermyon Spin Cloud** for serverless WASM hosting with server mode support.

> **Prerequisites:** 
> - Linux host with containerd installed
> - Docker is used for traditional containers (Task 2)
> - containerd + `ctr` CLI is used for WASM containers (Task 3)
> - CLI mode benchmarks are the primary comparison; server mode requires Spin (Bonus Task)

**Key Insight:** You'll use the **exact same `main.go`** file for all three deployment targets:
1. **Traditional Docker** → native Linux binary → `net/http` server (CLI + server modes)
2. **WASM container via `ctr`** → TinyGo WASM binary → CLI mode only (WASI Preview1 limits)
3. **Spin Cloud** (Bonus) → same WASM binary → WAGI mode → HTTP server

This demonstrates "write once, compile anywhere" with significantly better performance characteristics for WASM.

---

## Tasks

### Task 1 — Create the Moscow Time Application (2 pts)

**Objective:** Build a Go application that works in both server mode (HTTP) and CLI mode (one-shot JSON output).

#### 1.1: Navigate to Lab Directory

1. **Navigate to the lab folder:**

   ```bash
   cd labs/lab12
   ```

   > **Note:** The `main.go` and `spin.toml` reference files are already provided in this directory. You'll work directly here for all tasks.

#### 1.2: Review the Go Application

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
   go run main.go
   # Visit http://localhost:8080 in another terminal
   
   # Test CLI mode
   MODE=once go run main.go
   ```

In `labs/submission12.md`, document:
- Screenshot of CLI mode output (`MODE=once`)
- Screenshot of server mode running in browser (if tested)
- Confirmation that you're working directly in `labs/lab12/` directory
- Explanation of how the single `main.go` works in three different contexts

---

### Task 2 — Build Traditional Docker Container (3 pts)

**Objective:** Create a minimal Docker container using traditional Go compilation and measure its performance.

#### 2.1: Review the Provided Dockerfile

1. **Examine the provided `Dockerfile`:**

   The `Dockerfile` is already in `labs/lab12/Dockerfile`. Review its contents:

   - **Build stage:** Uses `golang:1.21-alpine` to compile the Go binary
   - **Optimization flags:** `-tags netgo -trimpath -ldflags="-s -w -extldflags=-static"` for minimal size
   - **Run stage:** Uses `FROM scratch` (truly empty base image) for smallest possible image
   - **Static binary:** No external dependencies, fully self-contained

   > **Note:** We use `FROM scratch` (truly empty base image) instead of Alpine for the fairest comparison with WASM containers. The optimization flags produce a minimal, fully static binary with no external dependencies.

#### 2.2: Build and Run Traditional Container

1. **Ensure you're in the lab directory:**

   ```bash
   cd labs/lab12
   ```

2. **Clean up any previous containers (optional but recommended):**

   ```bash
   docker rm -f test-traditional test-wasm 2>/dev/null || true
   docker image prune -f 2>/dev/null || true
   ```

3. **Build Container:**

   ```bash
   docker build -t moscow-time-traditional -f Dockerfile .
   ```

4. **Test CLI Mode:**

   ```bash
   docker run --rm -e MODE=once moscow-time-traditional
   ```

5. **Test Server Mode (Optional):**

   ```bash
   docker run --rm -p 8080:8080 moscow-time-traditional
   ```

   Test in browser: `http://localhost:8080`

#### 2.3: Measure Performance

1. **Check Binary Size:**

   ```bash
   # Extract and check binary size
   docker create --name temp-traditional moscow-time-traditional
   docker cp temp-traditional:/app/moscow-time ./moscow-time-traditional
   docker rm temp-traditional
   ls -lh moscow-time-traditional
   ```

2. **Check Image Size:**

   ```bash
   docker images moscow-time-traditional
   
   # More precise size measurement
   docker image inspect moscow-time-traditional --format '{{.Size}}' | \
       awk '{print $1/1024/1024 " MB"}'
   ```

3. **Startup Time Benchmark (CLI Mode):**

   ```bash
   # Compute average automatically
   for i in {1..5}; do
       /usr/bin/time -f "%e" docker run --rm -e MODE=once moscow-time-traditional 2>&1 | tail -n 1
   done | awk '{sum+=$1; count++} END {print "Average:", sum/count, "seconds"}'
   ```

4. **Memory Usage (Server Mode):**

   In one terminal:
   ```bash
   docker run --rm --name test-traditional -p 8080:8080 moscow-time-traditional
   ```

   In another terminal:
   ```bash
   docker stats test-traditional --no-stream
   ```

In `labs/submission12.md`, document:
- Binary size from `ls -lh moscow-time-traditional`
- Image size from both `docker images` and `docker image inspect`
- Average startup time across 5 CLI mode runs
- Memory usage from `docker stats` (MEM USAGE column)
- Screenshot of application running in browser (server mode)

---

### Task 3 — Build WASM Container (ctr-based) (3 pts)

**Objective:** Create a WebAssembly container using TinyGo to compile the **same `main.go`** file, package it as an OCI image, and run it via containerd's `ctr` CLI with a WASI runtime shim.

> **Prerequisites:**
> - Linux host with containerd running
> - Wasmtime shim binary installed at `/usr/local/bin/containerd-shim-wasmtime-v1`
> - Shim registered in containerd configuration (covered in setup steps below)
> - `ctr` CLI (comes with containerd)

> **Note:** We use `ctr` (containerd's native CLI) rather than `nerdctl` for simplicity. Docker Buildx creates the OCI archive, then `ctr` imports and runs it with the Wasmtime runtime.

#### 3.1: Capture TinyGo Version

1. **Record Build Environment:**

   ```bash
   docker run --rm tinygo/tinygo:0.39.0 tinygo version
   ```

#### 3.2: Build WASM Binary Using TinyGo

1. **Ensure you're in the lab directory:**

   ```bash
   cd labs/lab12
   ```

2. **Compile to WASM:**

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
   
   # Windows (CMD):
   docker run --rm \
       -v %cd%:/src \
       -w /src \
       tinygo/tinygo:0.39.0 \
       tinygo build -o main.wasm -target=wasi main.go
   ```

3. **Verify WASM Binary:**

   ```bash
   ls -lh main.wasm
   file main.wasm
   ```

#### 3.3: Review the WASM Dockerfile

1. **Examine the provided `Dockerfile.wasm`:**

   The `Dockerfile.wasm` is already in `labs/lab12/Dockerfile.wasm`. Review its contents:

   - **Base image:** `FROM scratch` (empty base, same as traditional Dockerfile)
   - **Content:** Only copies the `main.wasm` binary
   - **Entry point:** Directly executes the WASM module
   - **Size:** Extremely minimal - just the WASM binary plus minimal OCI metadata

   > **Note:** This is a WASI module. The `EXPOSE` directive is informational only and doesn't enable networking. The actual runtime (wasmtime shim) handles WASM execution.

#### 3.4: Build and Run WASM Container

**Install and Verify Prerequisites:**

Before building, ensure your environment is ready:

1. **Install containerd (if not already installed):**

   ```bash
   # For Ubuntu/Debian
   sudo apt-get update
   sudo apt-get install -y containerd
   
   # Start and enable containerd
   sudo systemctl enable --now containerd
   sudo systemctl status containerd
   # Should show "active (running)"
   ```

2. **Verify ctr is available:**

   ```bash
   # ctr comes bundled with containerd
   ctr --version
   ```

   You should see output like: `ctr containerd.io 1.x.x`

3. **Install the Wasmtime runtime shim:**

   We'll **build the shim from source using Docker** (no Rust installation needed!):

   ```bash
   # Build the wasmtime shim using Docker (takes ~5-10 minutes)
   docker run --rm \
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


   # Install the shim to /usr/local/bin
   sudo install -D -m0755 containerd-shim-wasmtime-v1 /usr/local/bin/
   
   # Verify installation
   ls -la /usr/local/bin/containerd-shim-wasmtime-v1
   ```

   > **Why Docker?** This approach avoids installing Rust toolchain on your host system. The container handles all build dependencies (Rust, Cargo, libseccomp, protobuf, etc.) automatically, and outputs only the compiled shim binary.

4. **Configure containerd to register the wasmtime shim:**

   > **Why configure containerd?** While `ctr` can use the shim binary directly, registering it in containerd's configuration ensures it's available for Kubernetes and other CRI clients. It's good practice for production environments.

   ```bash
   # Backup existing config if present
   sudo cp /etc/containerd/config.toml /etc/containerd/config.toml.backup 2>/dev/null || true
   
   # Generate default config if you don't have one
   sudo mkdir -p /etc/containerd
   containerd config default | sudo tee /etc/containerd/config.toml >/dev/null
   ```

   **Manually add the wasmtime runtime configuration:**

   Open the config file with your preferred editor:

   ```bash
   sudo nano /etc/containerd/config.toml
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
   sudo systemctl restart containerd
   sudo systemctl status containerd --no-pager
   # Should show "active (running)"
   ```

   **Verify the wasmtime runtime is correctly registered:**

   ```bash
   # Check the runtimes section in the active config
   sudo containerd config dump | sed -n "/io.containerd.cri.v1.runtime'.containerd/,/^\[/p" | sed -n '/runtimes/,+20p'
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
   ls -la /usr/local/bin/containerd-shim-wasmtime-v1
   
   # Verify containerd is running
   sudo ctr version
   ```

**Build OCI Archive and Import into containerd:**

1. **Build WASI image to OCI archive using Docker Buildx:**

   ```bash
   docker buildx build \
      --platform=wasi/wasm \
      -t moscow-time-wasm:latest \
      -f Dockerfile.wasm \
      --output=type=oci,dest=moscow-time-wasm.oci,annotation=index:org.opencontainers.image.ref.name=moscow-time-wasm:latest \
      .
   ```

   > **What this does:** Docker Buildx builds for the `wasi/wasm` platform and creates an OCI-compliant image archive. This archive can be imported into any OCI-compatible image store, including containerd.

2. **Import the OCI archive into containerd:**

   ```bash
   sudo ctr images import \
      --platform=wasi/wasm \
      --index-name docker.io/library/moscow-time-wasm:latest \
      moscow-time-wasm.oci
   ```

3. **Verify the image was imported:**

   ```bash
   sudo ctr images ls | grep -E 'moscow-time-wasm|wasi|wasm'
   ```

   You should see: `docker.io/library/moscow-time-wasm:latest`

**Run WASM Container with ctr:**

1. **Test CLI Mode (one-shot run):**

   ```bash
   sudo ctr run --rm \
      --runtime io.containerd.wasmtime.v1 \
      --platform wasi/wasm \
      --env MODE=once \
      docker.io/library/moscow-time-wasm:latest wasi-once
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

#### 3.5: Measure WASM Performance

1. **Check Sizes:**

   ```bash
   # Binary size
   ls -lh main.wasm
   
   # Image size (ctr images ls)
   sudo ctr images ls | awk 'NR>1 && $1 ~ /moscow-time-wasm/ {print "IMAGE:", $1, "SIZE:", $4}'
   ```

2. **Startup Time Benchmark (CLI Mode with unique names):**

   > **Important:** `ctr run` requires unique container names for each invocation. We generate unique names using timestamps.

   ```bash
   for i in {1..5}; do
       NAME="wasi-$(date +%s%N | tail -c 6)-$i"
       /usr/bin/time -f "%e" sudo ctr run --rm \
           --runtime io.containerd.wasmtime.v1 \
           --platform wasi/wasm \
           --env MODE=once \
           docker.io/library/moscow-time-wasm:latest "$NAME" 2>&1 | tail -n 1
   done | awk '{sum+=$1; n++} END{printf("Average: %.4f seconds\n", sum/n)}'
   ```

3. **Memory Usage:**

   Memory reporting for WASM containers via `ctr` is typically not available. WASM runs in a sandboxed runtime with different resource accounting mechanisms than traditional Linux containers. 
   
   **What to document:** State "N/A - not available via ctr" and explain that WASM uses a different execution model. The wasmtime runtime manages WASM memory internally, and traditional container metrics (cgroups) don't apply.

In `labs/submission12.md`, document:
- TinyGo version used
- WASM binary size (from `ls -lh main.wasm`)
- WASI image size (from `ctr images ls`)
- Average startup time from the `ctr run` benchmark loop (CLI mode)
- Explanation of why server mode doesn't work under `ctr` (WASI Preview1 lacks socket support)
- Note that server mode **can** be demonstrated via Spin using the same `main.wasm`
- Memory usage reporting (likely "N/A" with explanation)
- Note: used **same source code** as traditional build
- Confirmation that you used `ctr` (containerd CLI) for WASM execution

---

### Task 4 — Performance Comparison & Analysis (2 pts)

**Objective:** Analyze and compare the performance characteristics of traditional vs WASM containers built from the **same source code**.

#### 4.1: Create Comprehensive Comparison Table

| Metric | Traditional Container | WASM Container | Improvement | Notes |
|--------|----------------------|----------------|-------------|-------|
| **Binary Size** | ___ MB | ___ MB | __% smaller | From `ls -lh` |
| **Image Size** | ___ MB | ___ MB | __% smaller | From `docker image inspect` |
| **Startup Time (CLI)** | ___ ms | ___ ms | __x faster | Average of 5 runs |
| **Memory Usage** | ___ MB | ___ MB or N/A | __% less | From `docker stats` |
| **Base Image** | scratch | scratch | Same | Both minimal |
| **Source Code** | main.go | main.go | Identical | ✅ Same file! |
| **Server Mode** | ✅ Works (net/http) | ❌ Not via ctr <br> ✅ Via Spin (WAGI) | N/A | WASI Preview1 lacks sockets; <br> Spin provides HTTP abstraction |

**Improvement Calculation:**
- **Size reduction %**: `((Traditional - WASM) / Traditional) × 100`
- **Speed improvement factor**: `Traditional time / WASM time`
- **Memory reduction %**: `((Traditional - WASM) / Traditional) × 100`

#### 4.2: Analysis Questions

Answer the following in your submission:

1. **Binary Size Comparison:**
   - Why is the WASM binary so much smaller than the traditional Go binary?
   - What did TinyGo optimize away?

2. **Startup Performance:**
   - Why does WASM start faster?
   - What initialization overhead exists in traditional containers?

3. **Use Case Decision Matrix:**
   - When would you choose WASM over traditional containers?
   - When would you stick with traditional containers?

In `labs/submission12.md`, document:
- Complete comparison table with all metrics
- Calculated improvement percentages
- Detailed answers to all questions
- Recommendations for when to use each approach

---

### Bonus Task — Deploy to Fermyon Spin Cloud (Extra Credit)

**Objective:** Deploy your WASM application to Fermyon Spin Cloud for serverless edge hosting.

**Why This Matters:** Spin is a production-ready WASM serverless platform that showcases real-world WASM deployment with instant global distribution.

**🎯 Key Insight:** Your `main.go` already supports Spin! We'll use Spin's **WAGI executor** which runs your WASM in CGI mode—no SDK or code changes needed. The same file works for Docker (net/http), WASM containers (CLI mode), and Spin (WAGI mode).

#### B.1: Install Spin CLI

<details>
<summary>💻 Installation Commands</summary>

**Linux/macOS:**
```bash
curl -fsSL https://developer.fermyon.com/downloads/install.sh | bash
sudo mv spin /usr/local/bin/
```

**macOS (Homebrew):**
```bash
brew tap fermyon/tap
brew install fermyon/tap/spin
```

**Windows (PowerShell):**
```powershell
iwr https://developer.fermyon.com/downloads/install.ps1 -useb | iex
```

Verify installation:
```bash
spin --version
```

</details>

#### B.2: Review Spin Configuration (WAGI Mode)

1. **Examine the provided `spin.toml`:**

   The configuration file is already in `labs/lab12/spin.toml`.

   **Key Configuration Details:**
   
   - `executor = { type = "wagi" }` tells Spin to use WAGI mode (CGI-style execution)
   - Spin sets environment variables like `REQUEST_METHOD` and `PATH_INFO`
   - Your program reads these vars, prints HTTP headers to STDOUT, then prints the response body
   - No Spin SDK needed—pure Go standard library!

   > **Why WAGI?** WAGI (WebAssembly Gateway Interface) is a CGI-style protocol. Spin starts your WASM per request, sets env vars, and expects an HTTP response on STDOUT. This lets us use the **same `main.go`** across all platforms!

#### B.3: Prepare WASM Binary for Spin

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

#### B.4: Test Locally with Spin

1. **Verify you have the WASM binary:**

   ```bash
   ls -lh main.wasm
   ```

   You should see the `main.wasm` file from Task 3.

2. **Run Spin locally:**

   ```bash
   spin up
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

#### B.5: Deploy to Spin Cloud

1. **Sign Up for Fermyon Cloud:**

   Visit [https://cloud.fermyon.com](https://cloud.fermyon.com) and create a free account.

2. **Login via CLI:**

   ```bash
   spin login
   ```

   > **Note:** Some installations use `spin cloud login` instead. If `spin login` fails, try:
   > ```bash
   > spin cloud login
   > ```

3. **Deploy Application:**

   ```bash
   spin deploy
   ```

   Spin will provide a public URL like: `https://moscow-time-abc123.fermyon.app`

4. **Test Deployment:**

   ```bash
   curl https://your-deployment-url.fermyon.app/api/time
   ```

#### B.6: Measure and Compare Deployment Experience

1. **Measure deployment time:**

   ```bash
   # Time the deployment
   time spin deploy
   ```

   Document:
   - Upload time (shown in Spin output)
   - Total deployment time (from `time` command)

2. **Measure cold start latency:**

   After deployment, measure response times. First, save your deployment URL:

   ```bash
   # Replace with your actual Spin Cloud URL from the deployment output
   export SPIN_URL="https://moscow-time-abc123.fermyon.app"
   
   # Verify it works
   curl -s "$SPIN_URL/api/time" | jq .
   ```

   **Calculate averages:**

   ```bash
   # Cold start average
   echo "Cold start average:"
   for i in {1..5}; do
       curl -sS -o /dev/null -w "%{time_total}\n" "$SPIN_URL/?_cold=$(date +%s%N)" 2>&1
       sleep 5
   done | awk '{sum+=$1; n++} END {printf("Average: %.4f seconds\n", sum/n)}'
   
   # Warm average
   echo "Warm average:"
   for i in {1..5}; do
       curl -sS -o /dev/null -w "%{time_total}\n" "$SPIN_URL/api/time" 2>&1
       sleep 1
   done | awk '{sum+=$1; n++} END {printf("Average: %.4f seconds\n", sum/n)}'
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
   ```

In your **bonus section** of `labs/submission12.md`, document:

- Public URL of your deployed application (`$SPIN_URL`)
- Deployment time from `spin deploy` command output
- **Cold start measurements:**
  - Calculated average cold start time
- **Warm measurements:**
  - Calculated average warm time
  - Comparison with cold start times
- **Local Spin measurements:**
  - Calculated average local time
  - Comparison with cloud deployment
- **Reflection:**
  - Would you use Spin for production workloads? Why or why not?
  - How does this compare to traditional serverless (AWS Lambda, Cloud Functions)?

---

## How to Submit

1. Create a branch for this lab and push it to your fork:

   ```bash
   git switch -c feature/lab12
   # Work in labs/lab12/ directory for all tasks
   # Create labs/submission12.md with your findings
   git add labs/lab12/ labs/submission12.md
   git commit -m "docs: add lab12 submission"
   git push -u origin feature/lab12
   ```

2. Open a PR from your fork's `feature/lab12` branch → **course repository's main branch**.

3. In the PR description, include:

   ```text
   - [x] Task 1 — Create the Moscow Time Application
   - [x] Task 2 — Build Traditional Docker Container
   - [x] Task 3 — Build WASM Container
   - [x] Task 4 — Performance Comparison & Analysis
   - [ ] Bonus — Deploy to Fermyon Spin Cloud (if completed)
   
   Key Achievement: Used the same main.go for both traditional and WASM builds!
   Startup benchmarks performed using MODE=once for both targets.
   ```

4. **Copy the PR URL** and submit it via **Moodle before the deadline**.

---

## Acceptance Criteria

- ✅ Branch `feature/lab12` exists with commits for each task.
- ✅ File `labs/submission12.md` contains required outputs and analysis for Tasks 1-4.
- ✅ Single `main.go` file used for traditional Docker, WASM containers, and Spin (via WAGI).
- ✅ Both traditional and WASM containers built successfully.
- ✅ WASM CLI mode runs successfully and is benchmarked via `ctr` with io.containerd.wasmtime.v1 runtime.
- ✅ Startup benchmarks performed using `MODE=once` for both traditional Docker and WASM containers.
- ✅ Server mode limitation explained (WASI Preview1 lacks socket support).
- ✅ (Optional) Server mode demonstrated via Spin using the same `main.go`/`main.wasm`.
- ✅ Performance benchmarks completed with documented results.
- ✅ Comparison table shows clear performance differences.
- ✅ All 3 analysis questions answered thoughtfully.
- ✅ TinyGo version and build environment documented.
- ✅ PR from `feature/lab12` → **course repo main branch** is open.
- ✅ PR link submitted via Moodle before the deadline.
- 🎁 **Bonus:** Spin Cloud deployment completed using the same `main.go` with WAGI executor (no Spin SDK needed), `spin.toml` configured with `executor = { type = "wagi" }`, and deployment documented (extra credit).

---

## Rubric (10 pts + Bonus)

| Criterion                                       | Points |
| ----------------------------------------------- | -----: |
| Task 1 — Create the Moscow Time Application    |  **2** |
| Task 2 — Build Traditional Docker Container    |  **3** |
| Task 3 — Build WASM Container                  |  **3** |
| Task 4 — Performance Comparison & Analysis     |  **2** |
| **Total (Required)**                           | **10** |
| **Bonus — Deploy to Fermyon Spin Cloud**       | **+2** |
| **Maximum Possible**                           | **12** |

**Note:** The bonus task provides extra credit that can boost your overall grade or serve as a buffer for other assignments.

---

## Guidelines

- Use clear Markdown headers to organize sections in `submission12.md`.
- Include both command outputs and written analysis for each task.
- Use `MODE=once` for reliable, consistent benchmarking.
- Document whether WASM server mode worked (accept either outcome).
- Take screenshots showing both containers running.
- Emphasize that you used **identical source code** for both builds.
- Provide thoughtful answers to all analysis questions.
- Run benchmarks multiple times for accurate averages.
- **Bonus task is optional** but highly recommended for learning cutting-edge WASM deployment.

<details>
<summary>📚 Helpful Resources</summary>

**Core Technologies:**
- [TinyGo Documentation](https://tinygo.org/docs/)
- [Docker WASM Documentation](https://docs.docker.com/desktop/wasm/)
- [WasmEdge Runtime](https://wasmedge.org/)
- [WebAssembly Official Site](https://webassembly.org/)
- [WASI Documentation](https://wasi.dev/)

**Spin Platform:**
- [Fermyon Spin Documentation](https://developer.fermyon.com/spin)
- [Spin Quickstart](https://developer.fermyon.com/spin/quickstart)
- [Spin Cloud Documentation](https://developer.fermyon.com/cloud/index)
- [Spin with TinyGo](https://developer.fermyon.com/spin/go-components)

**Build Optimization:**
- [Go Build Tags](https://pkg.go.dev/cmd/go#hdr-Build_constraints)
- [Go Linker Flags](https://pkg.go.dev/cmd/link)

</details>

<details>
<summary>💡 Key Concepts</summary>

**Same Source, Multiple Targets:**
- Traditional Docker: `go build` → native Linux binary → `net/http` server
- WASM container: `tinygo build -target=wasi` → WebAssembly binary → CLI mode
- Spin Cloud: Same WASM binary → WAGI mode (CGI-style) → global edge
- **One `main.go` file** works everywhere—detects context automatically!

**MODE=once Design Pattern:**
- Provides reliable startup benchmark
- Guarantees functionality even without networking
- Apples-to-apples comparison
- Useful for CI/CD health checks

**Spin Platform Benefits:**
- Serverless WASM hosting
- Global edge deployment (Fastly CDN)
- Microsecond cold starts
- No container orchestration needed
- Git-based deployment workflow

**Build Optimization:**
- `CGO_ENABLED=0`: Pure Go, no C dependencies
- `-tags netgo`: Use Go native network stack
- `-trimpath`: Remove file system paths for reproducible builds
- `-ldflags="-s -w"`: Strip debug symbols and DWARF
- `-extldflags=-static`: Fully static linking
- Result: Minimal, portable binary

</details>

<details>
<summary>🎯 Expected Performance Improvements</summary>

Based on typical Go → TinyGo WASM compilation:

**Binary Size:**
- Standard Go (with optimizations): ~5-8 MB
- TinyGo WASM: ~500 KB - 1.5 MB
- **Improvement: 80-90% smaller**

**Image Size:**
- Traditional (scratch-based): ~6-10 MB
- WASM (scratch-based): ~1-2 MB
- **Improvement: 80-90% smaller**

**Startup Time (CLI mode):**
- Traditional container: ~100-300ms
- WASM container: ~20-100ms
- Spin deployment: Spin claims <5ms cold start - **measure yours and report actual numbers**
- **Expected improvement: 2-5x faster (containers), potentially 20-60x faster (Spin if it meets claims)**

**Deployment:**
- Traditional: Build → Push → Pull → Run (minutes)
- WASM containers: Build → Run (seconds)
- Spin: Build → Deploy (seconds, global edge)

</details>

<details>
<summary>⚠️ Known Limitations & Troubleshooting</summary>

**WASM/WASI Preview1 Limitations:**
- **No TCP/UDP sockets**: Cannot open network connections directly (wasi-sockets is Preview2)
- **No timezone database**: Limited system resource access → use `time.FixedZone` instead of `time.LoadLocation`
- **Restricted file I/O**: Only preopened directories are accessible
- **Single-threaded**: No goroutine parallelism across CPU cores
- **Smaller stdlib**: TinyGo implements a subset of Go's standard library
- **Workaround**: Use platforms like Spin that provide HTTP abstraction via WAGI

**Expected Behavior:**
- **CLI mode** (`MODE=once`): Works reliably for both Docker and WASM via `ctr`
- **Server mode (Docker)**: Works via `net/http`
- **Server mode (WASM via `ctr`)**: Does NOT work → WASI Preview1 lacks TCP socket support
- **Server mode (Spin)**: Works via WAGI (CGI-style HTTP abstraction)
- **Memory stats**: N/A for WASM → different resource accounting model

**Spin-Specific Issues:**

**Issue: Spin build fails**
- **Solution**: Ensure TinyGo is installed or use Docker build command
- Check `spin.toml` syntax is correct
- Verify component name matches in all sections

**Issue: Spin deploy fails**
- **Solution**: Ensure you're logged in: `spin login`
- Check internet connectivity
- Verify application name is unique

**Issue: Application doesn't respond on Spin Cloud**
- **Solution**: Check route is set to `/...` in `spin.toml`
- Verify HTTP handler responds to GET requests
- Check Spin logs: `spin cloud logs <app-name>`

**Issue: Build command in spin.toml fails**
- **Solution**: Test build command separately first
- For Windows, adjust Docker volume mounting syntax
- Consider using pre-built `main.wasm` and removing build command

</details>

<details>
<summary>🚀 Real-World WASM Applications</summary>

**Current Production Use:**

1. **Cloudflare Workers**
   - WASM-powered serverless functions
   - Sub-millisecond cold starts
   - Global edge deployment

2. **Fastly Compute@Edge**
   - WASM for edge computing
   - Same code runs worldwide
   - Instant scaling

3. **Fermyon Spin (This Lab!)**
   - WASM microservices framework
   - Microsecond startup times
   - Global edge via Fastly
   - Production-ready platform

4. **Shopify Functions**
   - WASM-based customizations
   - Safe merchant code execution
   - No infrastructure management

**Why Spin Matters for This Lab:**
- **Solves networking limitation**: Provides HTTP server via WAGI (no WASI sockets needed)
- **Same binary**: Uses the `main.wasm` you already built → no rebuild or code changes
- **Developer Experience**: Simple CLI, Git-based deployment workflow
- **Performance**: Sub-5ms cold starts globally (measure yours!)
- **Portability**: Same WASM runs on Spin Cloud, self-hosted Spin, or Kubernetes + SpinKube
- **Edge deployment**: Automatic global distribution via Fastly CDN

</details>

<details>
<summary>🌐 Spin Platform Deep Dive</summary>

**What is Spin?**
- Open-source framework for building WASM applications
- Created by Fermyon (founded by Deis co-founder)
- Built on WebAssembly Component Model
- Supports multiple languages (Rust, Go, JavaScript, Python)

**Spin Architecture:**
```
Your Code → TinyGo WASM → Spin Runtime → Wasm Runtime (Wasmtime)
                                      ↓
                           HTTP Trigger/Router
                                      ↓
                          Fastly Global Edge (Spin Cloud)
```

**Spin vs Traditional Serverless:**

| Feature | AWS Lambda | Spin Cloud |
|---------|-----------|------------|
| **Cold Start** | 100-1000ms | <5ms |
| **Runtime** | Container | WASM |
| **Size Limit** | 250MB | ~50MB practical |
| **Languages** | Many | Rust, Go, JS, Python (WASM) |
| **Edge** | Regional | Global (Fastly) |
| **Billing** | Per 100ms | Per request |

**Spin Benefits Over Docker WASM:**
- Built-in HTTP triggers and routing
- Automatic TLS certificates
- Environment variable management
- Built-in key-value storage
- SQLite support
- Redis integration
- Simple deployment workflow

**When to Use Spin:**
- ✅ Serverless APIs and microservices
- ✅ Edge functions and middleware
- ✅ WebHooks and event handlers
- ✅ Static site APIs
- ❌ Long-running processes
- ❌ Large stateful applications
- ❌ Applications requiring extensive system access

</details>
