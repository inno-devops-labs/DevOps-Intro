# HF Space Dockerfile for QuickNotes.
#
# Pulls the already-built, already-scanned, already-signed-off image from
# ghcr.io (Lab 10 Task 1 release) rather than rebuilding from app/ source.
# See submissions/lab10.md design question (f) for the reproducibility vs
# build-inside-the-Space trade-off.
FROM ghcr.io/ivanalpatov2003-design/devops-intro/quicknotes:0.1.0

# QuickNotes already defaults to :8080 (see app/main.go envOrDefault("ADDR", ":8080")),
# matching the app_port declared in README.md's frontmatter below - set explicitly
# anyway for clarity.
ENV ADDR=":8080"

# The original Lab 6 Compose stack wrote notes to a named volume mounted at /data,
# with ownership fixed up by an init-data step (chown to the nonroot UID 65532).
# HF Spaces just runs this Dockerfile directly - no volume, no init step - so the
# default relative DATA_PATH would try to write into the read-only image filesystem.
# /tmp is writable regardless of UID, so redirect storage there. Data is ephemeral
# across Space restarts/rebuilds - acceptable for this demo deployment.
ENV DATA_PATH="/tmp/notes.json"

# SEED_PATH stays at its default ("seed.json", i.e. /seed.json inside the image,
# where the Dockerfile in app/ copied it) - no override needed.

EXPOSE 8080
