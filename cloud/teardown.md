# Lab 10 Teardown

## Hugging Face Space

Space page -> **Settings** tab -> **Delete this Space** (Danger Zone). Or leave
it: on the free tier it sleeps after ~30 min idle and costs nothing.

## GHCR package

**Not** torn down on purpose: the public, pullable image is the Task 1
deliverable and must stay available. To remove it you would go to the package
page -> **Package settings** -> **Delete package**.

## Cloudflare quick tunnel (bonus)

Ephemeral by design: `Ctrl-C` the `cloudflared` process and the
`*.trycloudflare.com` URL stops resolving immediately. Nothing persists and
there is no account state to clean up.
