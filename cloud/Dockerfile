# Hugging Face Space (Docker SDK) — serve the exact image the release CI pushed
# to ghcr.io. We PULL the immutable tag rather than rebuild from source, so the
# Space runs the same artifact CI built and Lab 9 scanned (reproducible, no build
# drift). Trade-off discussed in design question (f).
FROM ghcr.io/rikire/devops-intro/quicknotes:v0.1.0

# The base image already: runs as nonroot (uid 65532), ENTRYPOINT ["/quicknotes"],
# listens on :8080 (0.0.0.0), and ships seed data. README.md frontmatter sets
# `app_port: 8080` so HF routes the public URL to this port.
EXPOSE 8080
