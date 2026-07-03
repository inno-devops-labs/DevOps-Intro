# The Space runs the exact image that the Task 1 release workflow pushed to
# ghcr.io: the artifact serving the public URL is the same one Lab 9 scanned
# and Task 1 tagged v0.1.0. Trade-offs vs building from source in the Space
# are discussed in submissions/lab10.md (design question f).
FROM ghcr.io/dekart-hub/devops-intro/quicknotes:v0.1.0

# Hugging Face may run the container under a different uid than the image's
# nonroot user, in which case the baked-in /data directory is not writable.
# /tmp is writable for any uid and Space storage is ephemeral anyway.
ENV DATA_PATH=/tmp/notes.json
