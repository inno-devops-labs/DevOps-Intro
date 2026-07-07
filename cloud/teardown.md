# Teardown

## Hugging Face Space
Space settings (https://huggingface.co/spaces/Dnau15/quicknotes/settings)
→ Delete this Space → type the name to confirm.
Costs nothing while running (free CPU tier, sleeps after ~30 min idle), so
leaving it up is also fine.

## ghcr.io image
https://github.com/Dnau15?tab=packages → quicknotes → Package settings
→ Delete this package. (Left up for grading.)

## Cloudflare quick tunnel
Ctrl-C the `cloudflared` process — the ephemeral URL dies with it.
Nothing persists: no account, no config, no DNS records.

## Local container
docker compose down   # or: docker stop qn-ghcr
