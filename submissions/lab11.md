# Lab 11 — Reproducible builds with Nix

## Overview

The goal of this lab was to create a reproducible build process for the QuickNotes application using Nix flakes and verify that the same source produces identical build outputs in different environments.

The lab includes:

- reproducible Go binary build using `buildGoModule`;
- reproducibility verification in an independent environment;
- reproducible OCI image creation using `dockerTools.buildLayeredImage`;
- running the container as a non-root user;
- runtime verification of the QuickNotes API.

---

# Task 1 — Reproducible Go build

## Build configuration

The application is built using Nix:

```bash
nix build .#quicknotes -L
```

The build uses:

- `pkgs.buildGoModule`
- `vendorHash = null` because the project has no external Go dependencies;
- `CGO_ENABLED=0`;
- static linking with:

```text
-s -w
```

---

## Binary verification

The produced binary was checked:

```bash
file result/bin/quicknotes
```

Output:

```text
ELF 64-bit LSB executable, x86-64, statically linked, stripped
```

Dynamic dependencies:

```bash
ldd result/bin/quicknotes
```

Output:

```text
not a dynamic executable
```

The binary is fully static.

---

## Environment A build hash

The first build produced the following Nix store hash:

```text
sha256:0xahvadcdlkrb8x5i6x2a4nsr18a9b6yy8a45lm3d862wr952lhk
```

---

## Environment B build hash

The second build was performed inside an independent `nixos/nix` Docker environment.

The resulting hash was:

```text
sha256:0xahvadcdlkrb8x5i6x2a4nsr18a9b6yy8a45lm3d862wr952lhk
```

---

## Result

The hashes are identical.

This confirms that the QuickNotes binary build is reproducible across independent environments.

---

# Task 2 — Reproducible OCI image

## Image creation

The OCI image was built using:

```bash
nix build .#docker -L
```

The image was created with:

- `dockerTools.buildLayeredImage`;
- fixed creation timestamp;
- deterministic layers;
- non-root runtime user.

---

## OCI image reproducibility

First image build:

```text
cdbc538dd87e4f64a980e550ddf41134edabf5b9a15bbade7a83d1809156ae7d
```

Second image build:

```text
cdbc538dd87e4f64a980e550ddf41134edabf5b9a15bbade7a83d1809156ae7d
```

---

## Result

The image archive hashes are identical.

The OCI image generation is reproducible.

---

# Container configuration verification

The image was loaded:

```bash
docker load < result
```

Container metadata was checked.

## User

Command:

```bash
docker image inspect quicknotes:lab11 \
  --format '{{.Config.User}}'
```

Output:

```text
65532:65532
```

The container runs as a non-root user.

---

## Entrypoint

Command:

```bash
docker image inspect quicknotes:lab11 \
  --format '{{json .Config.Entrypoint}}'
```

Output:

```json
["/bin/quicknotes"]
```

---

## Exposed ports

Command:

```bash
docker image inspect quicknotes:lab11 \
  --format '{{json .Config.ExposedPorts}}'
```

Output:

```json
{"8080/tcp":{}}
```

---

# Runtime verification

The container was started:

```bash
docker run -d \
  --name quicknotes-lab11 \
  -p 8080:8080 \
  quicknotes:lab11
```

Container logs:

```text
quicknotes listening on :8080 (notes loaded: 4)
```

Health endpoint:

```bash
curl -i http://127.0.0.1:8080/health
```

Response:

```http
HTTP/1.1 200 OK
```

Body:

```json
{
  "notes": 4,
  "status": "ok"
}
```

---

# Conclusion

The QuickNotes application now has:

- reproducible Nix builds;
- identical outputs across independent environments;
- reproducible OCI image creation;
- deterministic image metadata;
- non-root container execution;
- successful runtime verification.
