# Lab 10 teardown

Both deploy targets are free, so nothing bills while idle. Cleanup anyway:

## Local (tunnel bonus)

```bash
docker rm -f tunnel quicknotes-v010
docker network rm lab10-tunnel
```

The quick tunnel URL is ephemeral: it dies with the cloudflared process and a
new run gets a new URL, so there is nothing to deregister.

## Hugging Face Space

Space settings -> Delete this Space. Or leave it: a sleeping free Space costs
nothing, it just cold-starts on the next visit.

## ghcr.io package

The `quicknotes` package can be deleted from the GitHub UI (Packages -> the
package -> settings) if the registry copy is no longer wanted. The `v0.1.0`
git tag stays: it is the release evidence for this lab.
