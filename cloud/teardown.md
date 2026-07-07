# Teardown

## Hugging Face Space

1. Open [huggingface.co/spaces](https://huggingface.co/spaces) → your Space → **Settings**.
2. Scroll to **Delete this Space** → confirm.

## ghcr.io package

The image stays in GitHub Packages (free). To remove:

1. Repo → **Packages** → `devops-intro/quicknotes` → **Package settings** → **Delete package**.

## Cloudflare quick tunnel

Stop the `cloudflared` process (`Ctrl+C`). The `*.trycloudflare.com` URL is discarded automatically.

## Local containers

```bash
docker compose down
```
