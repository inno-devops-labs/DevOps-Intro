---
title: QuickNotes
emoji: "🗒"
colorFrom: blue
colorTo: gray
sdk: docker
app_port: 8080
pinned: false
---

# QuickNotes

Tiny notes API from the Innopolis DevOps course, deployed as a Docker Space.
QuickNotes listens on 8080, so `app_port` above overrides the Spaces default
of 7860.

Endpoints:

- `GET /health` - liveness plus note count
- `GET /notes` - list notes
- `POST /notes` - create a note (JSON: title, body)
- `GET /notes/{id}` - fetch one note
- `DELETE /notes/{id}` - delete a note
- `GET /metrics` - Prometheus text metrics
