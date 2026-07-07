---
title: QuickNotes
emoji: 📝
colorFrom: blue
colorTo: indigo
sdk: docker
app_port: 8080
pinned: false
---

# QuickNotes

A minimal REST API for managing notes, deployed via Docker on Hugging Face Spaces.

## Endpoints

- `GET /health` — health check
- `GET /notes` — list all notes
- `POST /notes` — create a note (`{"title":"...","body":"..."}`)
- `GET /notes/{id}` — get a note by ID
- `DELETE /notes/{id}` — delete a note
- `GET /metrics` — Prometheus metrics
