# Lab 10 teardown

## Hugging Face Space

1. Open https://huggingface.co/spaces/IlyaPechersky/quicknotes-lab10/settings
2. Scroll to **Delete this Space**
3. Confirm deletion

## Cloudflare quick tunnel

Stop the local `cloudflared` process. Quick tunnel URLs are ephemeral and stop working when the process exits.

## GitHub Container Registry package

The `quicknotes` package can stay public for course review. To remove it later:

1. Open https://github.com/users/IlyaPechersky/packages/container/devops-intro%2Fquicknotes/settings
2. Delete the package version or the whole package if no longer needed

## Git tag

```bash
git push --delete origin v0.1.0
git tag -d v0.1.0
```
