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

A minimal Go JSON API for notes, deployed here from the pre-built image published to
`ghcr.io/ivanalpatov2003-design/devops-intro/quicknotes:0.1.0` (Lab 10, Innopolis DevOps-Intro course).

## Endpoints

- `GET /health` - liveness + note count
- `GET /notes` - list notes
- `POST /notes` - create a note
- `GET /notes/{id}` - fetch one note
- `DELETE /notes/{id}` - delete a note
- `GET /metrics` - Prometheus-format metrics

## Notes on this deployment

- Data is stored at `/tmp/notes.json` inside the container - **ephemeral**, reset whenever the
  Space rebuilds or restarts. This is a demo deployment, not a persistence guarantee.
- HF Spaces on the free tier sleep after ~30 minutes of inactivity; the first request after
  sleep triggers a cold start (container wake + app init).
