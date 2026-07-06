# Teardown — Lab 10

Both targets cost $0, but here is how to remove everything.

## Hugging Face Space
- Space → **Settings** → **Delete this Space** (bottom of the page). This removes
  the container and the public `*.hf.space` URL. Nothing else is billed.

## ghcr.io image
- Your GitHub profile → **Packages** → `quicknotes` → **Package settings** →
  **Delete this package** (or **Manage versions** to delete a single tag).
- To stop future publishes, delete the git tag: `git push origin :refs/tags/v0.1.0`.

## Cloudflare quick tunnel (Bonus)
- Just stop the `cloudflared` process (Ctrl-C). Quick tunnels are ephemeral —
  the `*.trycloudflare.com` URL disappears when the process ends. No account,
  nothing to clean up.
