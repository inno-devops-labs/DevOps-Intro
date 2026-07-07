---
title: QuickNotes
emoji: 📝
colorFrom: blue
colorTo: purple
sdk: docker
app_port: 8080
pinned: false
short_description: Minimal Go notes JSON API (DevOps-Intro Lab 10)
---

# QuickNotes

A minimal Go notes API, deployed here straight from the image CI built and
pushed to `ghcr.io/ilnarkhasanov/devops-intro/quicknotes:0.1.0` (Lab 10, Task 1).

Endpoints:
- `GET /health` — status + note count
- `GET /metrics` — Prometheus-format metrics
- `GET /notes`, `POST /notes`, `GET /notes/{id}`, `DELETE /notes/{id}`

Source: [ilnarkhasanov/DevOps-Intro](https://github.com/ilnarkhasanov/DevOps-Intro)
