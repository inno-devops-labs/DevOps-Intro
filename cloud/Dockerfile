# Hugging Face Space (Docker SDK) for QuickNotes.
# We run the CI-published, Trivy-scanned image from ghcr.io rather than rebuilding
# in the Space, so the exact artifact tested in CI is what serves (see design f).
FROM ghcr.io/roukayazaki/devops-intro/quicknotes:v0.1.0

# HF runs the container as an arbitrary UID and gives no writable named volume,
# so point the notes file at /tmp (world-writable, ephemeral on the free tier).
ENV ADDR=":8080" \
    DATA_PATH="/tmp/notes.json" \
    SEED_PATH="/seed.json"

# QuickNotes listens on 8080; HF routes to it via app_port in README.md.
EXPOSE 8080
# ENTRYPOINT ["/qn"] is inherited from the base image.
