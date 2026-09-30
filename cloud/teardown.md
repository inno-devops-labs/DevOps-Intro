# Lab 10 Teardown

## Render

After the lab is graded, the `quicknotes-lab10` service can be suspended or deleted from the Render dashboard.

## Local resources

Any locally running QuickNotes process can be stopped with `Ctrl+C`.

## Secrets

The Render deploy hook is stored only as the GitHub Actions secret `RENDER_DEPLOY_HOOK`. The secret value is not committed to the repository.
