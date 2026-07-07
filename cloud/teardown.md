# Lab 10 Teardown

## Hugging Face Space

The Space is free, but it can be deleted after grading if desired:

1. Open the Space on Hugging Face.
2. Go to Settings.
3. Choose Delete this Space.
4. Type the Space name to confirm.

## Cloudflare Quick Tunnel

Quick tunnels are ephemeral. Stop the local tunnel with `Ctrl-C`; the public
`trycloudflare.com` URL becomes invalid. Stop the local QuickNotes container too:

```bash
docker rm -f quicknotes-lab10
```
