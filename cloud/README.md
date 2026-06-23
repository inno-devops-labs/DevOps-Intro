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

This Space runs the QuickNotes container published to `ghcr.io` by the Lab 10
release workflow. It's a Docker-SDK Space; `app_port: 8080` tells HF to route its
public proxy to QuickNotes' listener (HF defaults to 7860).

Endpoints once live at `https://<user>-quicknotes.hf.space`:
- `GET /health` → `{"notes":N,"status":"ok"}`
- `GET /notes`, `POST /notes`, `GET /notes/{id}`, `DELETE /notes/{id}`

> The files in this `cloud/` directory (`Dockerfile` + this `README.md`) are what
> you push to the Space's own Git repo. The Space rebuilds and serves on push.
