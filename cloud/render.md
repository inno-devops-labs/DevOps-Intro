# Render Free deployment

## Configuration

| Setting | Value |
|---|---|
| Service | `quicknotes-4rni4ka` (or an available suffix) |
| Source | Existing Image |
| Image configured at creation | `ghcr.io/4rni4ka/devops-intro/quicknotes:v0.1.1` |
| Image deployed through CI | `ghcr.io/4rni4ka/devops-intro/quicknotes:v0.1.3` |
| Instance | **Free**, explicitly override the preselected paid plan |
| Region | Frankfurt |
| Health check | `/health` |
| `PORT` | `10000` |
| `ADDR` | `:10000` |
| `DATA_PATH` (inherited image default) | `/data/notes.json` |
| `SEED_PATH` (inherited image default) | `/seed.json` |
| Persistent disk | None |

Existing Image reuses the image published by CI instead of rebuilding source on
another platform. The release is built for `linux/amd64`; the version tag must not
be reused. The image package must be public before Render can pull it.

Service ID: `srv-dblgvft9el5s73d15alg`. Public URL:
<https://quicknotes-4rni4ka.onrender.com>. New tag v0.1.3 was deployed by the
release workflow through its deploy hook, selecting image digest
`sha256:d9f659526c98b9b5e795e65b661764295a6dd5ff2b29a5fc196f63ff25705a64`.

## Deploy hook

In the service's Settings, copy its deploy hook into the fork's Actions secret
`RENDER_DEPLOY_HOOK`. Do not paste the hook into a tracked file, report, command
line argument, or CI log. With the hook on the clipboard, use:

```powershell
Get-Clipboard | gh secret set RENDER_DEPLOY_HOOK --repo 4rni4ka/DevOps-Intro
```

The release workflow sends an encoded `imgURL` with the new version. Host and
image name remain identical to the service's configured source. An accepted hook
starts a deployment; it does not by itself prove that `/health` is ready.

The workflow can publish the first image before a service exists. A missing hook
is explicitly reported as a bootstrap notice; Task 2 is complete only after the
secret exists and a subsequent tagged release redeploys the service.

## Verification

Save deploy log lines with `quicknotes listening on :10000` and verify `/health`
and `/notes` without credentials. Run `scripts/lab10/measure.py render URL` for
five immediate warm requests followed by three idle/wake cycles of at least
21 minutes each. Keep the dashboard and external monitors from making requests
during idle periods. The script records the pre-sleep note and checks its ID and
unique title after waking. On Free, the writable layer is discarded, so only
seed notes return. Do not infer this result without a live observation.

If Render asks for a card, use the Codespaces alternative in the assignment.

References: [Free instances](https://render.com/docs/free),
[deploy hooks](https://render.com/docs/deploy-hooks).
