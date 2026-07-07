# QuickNotes on Hugging Face Spaces (Docker SDK).
#
# We PULL the exact immutable image published to GHCR in Task 1 instead of
# rebuilding from app/ source. Rationale:
#   - the Space serves the identical, already-tested artifact (same digest),
#   - it builds in seconds (no Go toolchain, no module download),
#   - one source of truth for the release (GHCR), no drift.
# Trade-off (design question f): less in-Space debuggability and a hard
# dependency on GHCR being reachable at Space build time.
FROM ghcr.io/g-akleh/devops-intro/quicknotes:v0.1.0

# QuickNotes listens on :8080; HF routes to it via `app_port: 8080` in README.md.
# ENTRYPOINT ["/quicknotes"] and USER nonroot are inherited from the base image.
EXPOSE 8080
