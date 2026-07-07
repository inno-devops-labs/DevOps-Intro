---
title: QuickNotes
emoji: 📝
colorFrom: indigo
colorTo: blue
sdk: docker
app_port: 8080
pinned: false
---

# QuickNotes

Tiny Go notes API from the Innopolis DevOps course, deployed as a Docker Space.
The image is pulled from `ghcr.io/dnau15/devops-intro/quicknotes:v0.1.0`
(built and pushed by the tag-triggered release workflow in the course fork).

Endpoints: `GET /health`, `GET /notes`, `POST /notes`.
