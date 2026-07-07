---
title: QuickNotes
emoji: 📝
colorFrom: blue
colorTo: green
sdk: docker
app_port: 8080
pinned: false
---
# QuickNotes on Hugging Face Spaces

Runs the hardened QuickNotes container published to GitHub Container Registry and served using Hugging Face's Docker SDK.

- **Port:** `8080` (`app_port: 8080` is required because HF defaults to `7860`)
- **Image:** `ghcr.io/danielpancake/devops-intro/quicknotes:v0.1.0` (must be public)
- **Endpoints:** `/health`, `/notes`, `/notes/{id}`, `/metrics`
