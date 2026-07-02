# Lab 10 teardown

## Hugging Face Space

The free Space can be left running, but to remove it:

1. Open the Space on Hugging Face.
2. Go to `Settings`.
3. Use `Delete this Space`.

## Cloudflare quick tunnel

Stop `cloudflared` with `Ctrl+C`. The `trycloudflare.com` URL stops working immediately.

Stop the local container:

```powershell
docker rm -f quicknotes-lab10-tunnel
```

Remove the local data volume if it is no longer needed:

```powershell
docker volume rm quicknotes-lab10-data
```
