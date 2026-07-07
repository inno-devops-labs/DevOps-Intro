---
title: QuickNotes Lab 10
emoji: "📝"
colorFrom: blue
colorTo: green
sdk: docker
app_port: 8080
pinned: false
short_description: QuickNotes API deployed from the Lab 10 GHCR release image.
---

# QuickNotes Lab 10

This Hugging Face Space runs the immutable Lab 10 QuickNotes release image:

```text
ghcr.io/hidancloud/devops-intro/quicknotes:v0.1.0
```

The Space uses the Docker SDK and sets `app_port: 8080` because QuickNotes
listens on port 8080. The public API endpoints are:

```text
/health
/notes
/metrics
```
