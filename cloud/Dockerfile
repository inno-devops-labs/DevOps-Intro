# Hugging Face Space (Docker SDK) image for QuickNotes.
#
# Rationale (design question f): we PULL the immutable image already built and
# scanned by the Lab 10 release workflow instead of rebuilding from source in the
# Space. That guarantees the exact same, reproducible artifact runs in three
# places (CI, ghcr, HF), makes the HF build near-instant (just a pull), and keeps
# a single source of truth for the image. The cost is slightly less in-Space
# debuggability, which we accept for a tiny app.
#
# NOTE: replace the owner if you fork. ghcr names are lowercase.
FROM ghcr.io/1am6ada/devops-intro/quicknotes:v0.1.0

# QuickNotes listens on 0.0.0.0:8080 already; HF must be told the port via
# README app_port. Point persistent state at /tmp, which is writable on HF
# regardless of the runtime UID.
ENV ADDR=":8080" \
    DATA_PATH="/tmp/notes.json" \
    SEED_PATH="/app/seed.json"

EXPOSE 8080
