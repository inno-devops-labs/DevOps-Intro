# Lab 10 Teardown

## Hugging Face Space

Delete the Space from the Hugging Face UI:

1. Open the Space.
2. Go to `Settings`.
3. Choose `Delete this Space`.
4. Confirm the Space name.

Leaving the Space online is also acceptable for this lab because the public Docker Space tier is free and sleeps when idle.

## Cloudflare Quick Tunnel

Stop the foreground tunnel process with `Ctrl-C`. Then stop the local QuickNotes container:

```bash
docker stop quicknotes-lab10
```

Remove the local test volume if the notes data is no longer needed:

```bash
docker volume rm quicknotes-lab10-data
```
