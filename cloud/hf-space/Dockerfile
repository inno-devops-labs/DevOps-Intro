# Hugging Face Space (Docker SDK). Pulls the Lab 10 release image built and
# pushed by CI rather than rebuilding from app/ source — see submissions/lab10.md
# design question (f) for the trade-off.
FROM ghcr.io/ilnarkhasanov/devops-intro/quicknotes:0.1.0

# The base is FROM scratch (no shell, no pre-existing directories), so a /data
# directory can't be created with `RUN mkdir`. COPY --chown creates it instead,
# owned by the nonroot UID (65532) the binary runs as, so it's writable at runtime.
COPY --chown=65532:65532 data-placeholder /data

ENV DATA_PATH=/data/notes.json
