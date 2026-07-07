# Teardown notes

## Hugging Face Space

1. Open the Space settings page.
2. Delete the Space if you no longer need the public URL.
3. If you keep it, update the Docker image tag on the next release push.

## GitHub Container Registry

1. Open the package page for `ghcr.io/lime413/devops-intro/quicknotes`.
2. Keep the package public if you still want clean pulls without authentication.
3. Delete old tags only if they are no longer needed for reproducibility.

## Cloudflare Tunnel bonus

1. Stop the `cloudflared` process with `Ctrl+C`.
2. Confirm that the `trycloudflare.com` URL no longer responds.
3. Remove any local helper commands you created for the measurement session.
