# Teardown

Both deploy targets cost $0, but clean up anyway.

## Hugging Face Space
- Settings → **Delete this Space** (or **Pause** to keep it but stop it serving).
- Or `huggingface-cli repo delete <user>/quicknotes --type space`.

## ghcr.io image
- Repo → **Packages** → `quicknotes` → Package settings → **Delete package**
  (or delete individual version tags). Leaving it public is also fine — it's free.

## Cloudflare quick tunnel (bonus)
- Nothing persistent: just stop the `cloudflared` process (Ctrl-C). The
  `*.trycloudflare.com` URL is ephemeral and disappears on exit.
