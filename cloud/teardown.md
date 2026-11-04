# Teardown

- Render: in the service's Settings suspend the Free service, or delete it when
  the submission has been checked. Never select an upgrade or attach a paid disk.
- Quick tunnel: stop the recorded `cloudflared` process. The ephemeral public URL
  stops working; restart produces a different URL.
- Local container: `docker stop quicknotes-lab10` and
  `docker rm quicknotes-lab10` remove the disposable lab container.
- Codespaces fallback: `gh codespace delete -c NAME` also frees storage; stopping
  alone keeps consuming the included storage quota.
- Keep the release tag and public GHCR image for the grader. Revoke or regenerate
  the Render deploy hook if leaked, and update its Actions secret.

## Final state

Render is left on Free for grading. The quick-tunnel client was stopped after
the independent-network measurements. Removal of the two disposable local
containers (quicknotes-lab9-before, quicknotes-lab10) is deferred because
Docker Desktop is stopped; remove them with docker rm when the engine is
available. No persistent cloud disk or paid service was created.
