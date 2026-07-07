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

A tiny Go notes API deployed as a **Docker Space** for DevOps Lab 10. The Space
pulls its image from `ghcr.io/g-akleh/devops-intro/quicknotes:v0.1.0`, published
by CI in Task 1.

## Why `app_port: 8080`

Hugging Face routes external traffic to port **7860** by default. QuickNotes
listens on **8080**, so the Space frontmatter sets `app_port: 8080` to point HF
at the right port. The app itself is unchanged.

## Endpoints

- `GET /health` — liveness + note count
- `GET /notes` — list notes
- `GET /notes/{id}` — single note
- `POST /notes` — create a note
- `DELETE /notes/{id}` — delete a note

Source: <https://github.com/G-Akleh/DevOps-Intro>
