# Lab 10 submission

**Host:** <!-- e.g. Apple Silicon Mac -->. **Image:** <!-- ghcr.io/... -->. **HF Space:** <!-- URL -->.

---

## Task 1 — CI push to `ghcr.io`

### Release workflow

<!-- Paste or link `.github/workflows/release.yml` -->

### Registry & pull evidence

- **Image URL:** <!-- ghcr.io/<user>/<repo>/quicknotes:v0.1.0 -->
- **Clean pull:** <!-- `docker pull ...` output or screenshot -->

### CI release run

- **Green run:** <!-- https://github.com/.../actions/runs/... -->

### Design questions (a–c)

**a) OIDC vs `GITHUB_TOKEN`**

<!-- TODO -->

**b) `:latest` vs immutable `:v0.1.0`**

<!-- TODO -->

**c) `packages: write` scope only**

<!-- TODO -->

---

## Task 2 — Hugging Face Spaces

### Space URL & health check

- **Space:** <!-- https://<user>-<space>.hf.space -->
- **`curl -v` `/health`:** <!-- paste output -->

### Space repo files

<!-- Paste or link `cloud/` Dockerfile + README.md (frontmatter) -->

### Latency (scale-to-zero)

| Measurement | Value (s) |
|-------------|----------:|
| Warm p50 (5 requests) | |
| Cold #1 | |
| Cold #2 | |
| Cold #3 | |

### Design questions (d–f)

**d) HF sleep vs Cloud Run scale-to-zero**

<!-- TODO -->

**e) Why `app_port: 8080`?**

<!-- TODO -->

**f) Pull from ghcr.io vs build in Space**

<!-- TODO -->

---

## Bonus — Cloudflare Tunnel + comparison

### Quick tunnel

- **URL:** <!-- https://<random>.trycloudflare.com -->
- **Verified from other network:** <!-- cellular / other IP evidence -->

### Comparison table

| Metric | HF Spaces (hosted) | Cloudflare Tunnel (local-via-edge) |
|--------|-------------------:|-----------------------------------:|
| Warm p50 | | |
| Warm p95 | | |
| Cold start | | N/A (continuously local) |
| Public URL stability | stable | ephemeral on restart |
| Cost | free | free |

### Design questions (g–i)

**g) Which is "really cloud"?**

<!-- TODO -->

**h) Latency dominator (HF vs Tunnel)**

<!-- TODO -->

**i) When is Tunnel right for production?**

<!-- TODO -->

---

## Artifacts

| Path | Description |
|------|-------------|
| `.github/workflows/release.yml` | Tag → build → push to ghcr.io |
| `cloud/` | HF Space Dockerfile, README, tunnel notes |
| `submissions/attachments/lab10/` | Screenshots, curl logs, latency captures |
