---
---
title: QuickNotes
emoji: "📝"
colorFrom: blue
colorTo: green
sdk: docker
app_port: 8080
---

# QuickNotes on Hugging Face Spaces

This Space runs the QuickNotes API from the image published to GitHub Container Registry.

## Runtime

- Port: `8080`
- Source image: `ghcr.io/lime413/devops-intro/quicknotes:v0.1.0`
- SDK: Docker

## Health check

Use `/health` to verify the deployment:

```bash
curl -s https://REPLACE_WITH_SPACE_URL/health
```
