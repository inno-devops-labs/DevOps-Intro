# Teardown

## Hugging Face Space

Держу **tdzdslippen/quicknotes-lab10** публичным до проверки.

После — HF → Space → Settings → Delete this Space.

## GHCR

Образ можно оставить public для воспроизводимости. Удалить: GitHub → Packages → `devops-intro/quicknotes`.

## Cloudflare (bonus)

Ctrl+C на `cloudflared` — URL протухает сразу.

## Local

```bash
docker compose down -v
```
