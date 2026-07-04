---
title: QuickNotes
emoji: 📝
colorFrom: blue
colorTo: indigo
sdk: docker
app_port: 8080
pinned: false
short_description: A minimal JSON notes API built with Go
---

# QuickNotes

A tiny REST API for managing notes, built in Go and deployed as a Docker container.

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/health` | Health check |
| GET | `/notes` | List all notes |
| POST | `/notes` | Create a note (`{"title":"...","body":"..."}`) |
| GET | `/notes/{id}` | Get note by ID |
| DELETE | `/notes/{id}` | Delete note |
| GET | `/metrics` | Prometheus-style metrics |
