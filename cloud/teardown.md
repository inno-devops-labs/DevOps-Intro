# Lab 10 — tear down

## Hugging Face Space

1. Open https://huggingface.co/spaces → your QuickNotes Space
2. **Settings** → scroll to **Delete this Space** → confirm

Or leave it running (free tier sleeps after ~30 min idle).

## GHCR package

Package: `ghcr.io/selysecr332/devops-intro/quicknotes`

Optional: GitHub → your profile → **Packages** → `devops-intro/quicknotes` → **Package settings** → delete versions you no longer need.

## Cloudflare quick tunnel (bonus)

Stop the `cloudflared` process (Ctrl+C). The `*.trycloudflare.com` URL is ephemeral and stops working immediately.

## Git tag (optional)

```bash
git tag -d v0.1.0
git push origin :refs/tags/v0.1.0
```

Only delete the tag if you want to re-run the release workflow with the same version name.
