---
title: QuickNotes
emoji: 📝
colorFrom: blue
colorTo: green
sdk: docker
app_port: 8080
pinned: false
---

# QuickNotes

QuickNotes is the DevOps Intro notes API packaged as a Docker-based Hugging Face Space.

This Space deliberately pulls the release image from GitHub Container Registry:

```text
ghcr.io/whynotgm/devops-intro/quicknotes:v0.1.0
```

That keeps the Space deployment tied to the same immutable artifact produced by the release workflow instead of rebuilding from a drifting source checkout.
