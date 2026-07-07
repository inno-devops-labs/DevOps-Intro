# Lab 10 teardown

## Hugging Face Space

Delete the Space from the Hugging Face Space settings page after the lab if it is no longer needed.

## Local containers

Run:

docker compose down

## Cloudflare quick tunnel

Stop the cloudflared process with Ctrl+C. The trycloudflare URL is ephemeral and stops working when the process exits.