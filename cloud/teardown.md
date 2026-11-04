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
