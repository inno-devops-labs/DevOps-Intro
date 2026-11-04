# Lab 10 — QuickNotes release and cloud deployment

Date: 2026-11-04. Uses the updated Render version of Task 2 from upstream
`bad2887`, including CI deploy hook and note-persistence checks. The fork includes
the Lab 3 CI and Lab 9 hardened Lab 6 container prerequisites.

## Execution status

| Requirement | Status |
|---|---|
| Tag-triggered GHCR release workflow, both tags, minimum permissions, SHA-pinned actions | Implemented; live release evidence pending below |
| Public anonymous pull | Pending first publication and package visibility check |
| Render Free service, explicit port, health check, CI deploy hook | Configuration prepared; blocked on Render sign-in |
| Five warm requests, three 20+ minute idle/cold cycles, note loss after sleep | Not measured: needs a live Render service |
| Quick tunnel | Public `/health` verified locally; 50 warm hyperfine samples captured |
| Different-machine tunnel benchmark | Workflow prepared; remote run pending |
| Design questions a–i and teardown | Answered / documented |

Incomplete measurements are left explicit; no cold-start or note-loss values are
inferred from documentation.

## Task 1 — release pipeline

[release.yml](../.github/workflows/release.yml) runs on a `v*` tag, validates
`vMAJOR.MINOR.PATCH`, verifies the tagged source is on `origin/main`, tests the
app, builds `linux/amd64` from `app/`, and pushes:

- `ghcr.io/4rni4ka/devops-intro/quicknotes:v0.1.0`
- `ghcr.io/4rni4ka/devops-intro/quicknotes:latest`

Only the publishing job has `packages: write`; checkout needs `contents: read`.
It authenticates with the repository-scoped `GITHUB_TOKEN`. The sole third-party
action is pinned by a full 40-character SHA. Docker build/login/push use the
runner's CLI directly. Source, revision and version OCI labels connect the image
to the repository. The version tag is a release identifier and must never be
reused; the recorded registry digest is the content identity.

After pushing both tags, the workflow removes them locally and pulls the version
with a new, empty `DOCKER_CONFIG`. This proves anonymous access rather than
accidentally reusing cached registry credentials. On first publication GitHub
may require changing package visibility to public before rerunning this step.
Green run URL, tag signature, digest and clean-pull log will be added only after
they exist.

**a)** `GITHUB_TOKEN` is enough for GHCR attached to this repository. OIDC is useful
when Actions must authenticate to an external cloud role or identity system:
the provider validates issuer, audience and repository/ref claims and exchanges
them for short-lived credentials. This removes stored long-lived cloud keys and
allows trust to be limited to selected repositories/environments. It does not
automatically replace GHCR's package authorization.

**b)** `latest` is a convenient discovery/default channel for humans and demos.
Version tags support repeatable deployments and rollback; consumers needing
strict immutability should pin the digest because registries can also overwrite
version tags unless policy prevents it. The Render hook selects the new version,
not an ambiguous latest value.

**c)** Least privilege limits the damage from a compromised action or build step.
The publishing token can read source and write packages, but cannot use
`contents: write` to alter repository code/tags/releases or broadly modify other
repository resources as `write-all` would allow. Package write remains a real
capability: a compromised publisher could still poison a mutable image tag.

## Task 2 — Render

[cloud/render.md](../cloud/render.md) records the image source, **Free** instance,
Frankfurt region, health path `/health`, `PORT=10000`, `ADDR=:10000`, and ephemeral
`DATA_PATH=/data/notes.json`. The application code is not changed for port
discovery. No paid plan or card is used.

Render is the intended option. The dashboard currently requires sign-in, so no
service creation, live deployment, hook trigger, port log, `/health` curl, warm
latency, cold latency or note-persistence result is claimed yet. If Render asks
for a card after login, use the handout's Codespaces fallback instead.

The deploy-hook step reads `secrets.RENDER_DEPLOY_HOOK`, URL-encodes the versioned
`imgURL`, and avoids printing the secret. The first image can be published
before the service exists; a missing hook produces an explicit bootstrap notice.
Task 2 additionally requires adding the hook secret and demonstrating a later
tagged release actually redeploying the service.

[`scripts/lab10/measure.py`](../scripts/lab10/measure.py) records warm samples,
then **three 21-minute no-traffic cycles**. It POSTs a uniquely named disposable
note before each idle period and checks both ID and title after waking. It saves
raw responses, first-response latency and time until genuine QuickNotes JSON is
ready, so a Render HTML waiting page is not mistaken for a successful wake.
Run with no external monitor/dashboard requests to the application:

```sh
python scripts/lab10/measure.py render https://SERVICE.onrender.com --runs 5 --output submissions/evidence/lab10/render-measurements.json
```

**d)** Both Render spin-down and Cloud Run scale-to-zero release idle capacity,
but their startup targets differ. Render Free is a low-cost shared preview tier:
provisioning/scheduling, image setup and process startup can take about a minute.
Cloud Run is designed for request-driven autoscaling, with startup optimizations
and configurable minimum instances. A small Go process starting fast does not
remove the hosting platform's scheduling and routing delay. Actual results must
be measured rather than assuming either platform's marketing latency.

**e)** `PORT` communicates the listener expected by the platform; Docker `EXPOSE`
is image metadata, not a runtime instruction to bind or a guaranteed routing
contract. Here `PORT=10000` and `ADDR=:10000` agree from the first boot. A mismatch
can cause port detection and another restart/deploy cycle, lengthening rollout
and introducing another cold start; its exact cost is not measured yet.

**f)** An existing image reuses the CI-built, inspected artifact and avoids a
second build with potentially different tools/base layers. Render building from
Git simplifies setup and uses its build cache, but can produce a different
artifact unless every input is pinned. Version tags need a recorded digest for
strict identity. The expected note-loss mechanism is an ephemeral writable
filesystem discarded on Free spin-down/redeploy; a new instance seeds its file
again. The actual note result is still pending observation, not assumed.

## Bonus — local origin through Cloudflare edge

[cloud/tunnel.md](../cloud/tunnel.md) contains commands and versions. A quick
tunnel exposes the locally rebuilt `quicknotes:lab9` image through
`https://assured-opposed-leather-belief.trycloudflare.com`. `/health` returned
`{"notes":4,"status":"ok"}` without credentials. This preliminary local image
will be replaced by the public version-tagged GHCR image for the final same-image
comparison.

[hyperfine JSON](evidence/lab10/tunnel-local-hyperfine.json) and
[summary](evidence/lab10/tunnel-local-hyperfine.txt): version 2.0.0, five warmups,
50 measured requests, **p50 0.97791735 s**, **p95 1.4354554 s**. These were taken on
the origin's Windows host and are labeled local; they do not satisfy the
different-machine measurement requirement. The
[public tunnel benchmark workflow](../.github/workflows/tunnel-probe.yml) runs
the same test on a GitHub-hosted Ubuntu machine without GitHub authentication to
the endpoint, and prints all raw timings in its log.

| Metric | Render | Cloudflare Tunnel |
|---|---:|---:|
| Warm p50 | Pending deployment | 0.97791735 s locally; independent run pending |
| Warm p95 | Pending deployment | 1.4354554 s locally; independent run pending |
| Cold start, 3 cycles | Pending deployment | N/A while local process is running |
| Public URL stability | Stable service URL once created | Ephemeral; changes on restart |
| Cost | Free plan only | Free quick tunnel |

**g)** Render runs compute and the origin in its datacenter; Tunnel provides
managed cloud ingress while the origin remains on the laptop. Both use cloud
services, but only one outsources origin compute. Users care about availability,
latency, durability and trust boundaries; a sleeping laptop or home connection
still takes the tunneled API offline.

**h)** Warm Render latency is largely client-to-region RTT/TLS and routing when
the handler is tiny; a cold request adds platform wake time. Tunnel adds the
client-to-Cloudflare edge path, the edge-to-home connection and the local origin.
ISP upload, local network conditions and the laptop's load can dominate. The
measured curl wall time also includes DNS/TLS/process startup, not just Go work.

**i)** A managed named tunnel can be appropriate for home labs, on-prem services
and authenticated review environments when origin availability, access control
and network capacity are managed. An anonymous quick tunnel is useful for
temporary demos. A personal laptop quick tunnel is unsuitable for an always-on,
durable production notes service or sensitive unauthenticated data; no stable
URL, origin redundancy or availability guarantee is provided.

## Teardown and remaining evidence

[cloud/teardown.md](../cloud/teardown.md) explains cleanup. Keep registry/tag
evidence for grading. Render sign-in is the current missing input; the hook is
to be stored directly in Actions Secrets, never pasted into this report. No
Moodle submission for this incomplete Lab 10 is claimed.
