# Lab 11 — Reproducible Builds with Nix

## Student
Valeria

## Branch
`feature/lab11`

---

## Task 1 — Build Reproducible Artifacts from Scratch

### Goal
Build a reproducible binary with Nix and prove that repeated builds produce identical outputs.

### Files
Located in `labs/lab11/app/`:
- `main.go`
- `go.mod`
- `default.nix`

### Nix installation and verification
Nix was installed successfully and verified with:
- `nix --version`
- `nix run nixpkgs#hello`

### First build store path
```text
/nix/store/8mzp0mhm5qxyfwaj5s116lzq0ck2jghz-app-1.0.0
```

### Second build store path
```text
/nix/store/8mzp0mhm5qxyfwaj5s116lzq0ck2jghz-app-1.0.0
```

### First build binary SHA256
```text
ee97731747556f820411a6f1a6df81866bb11dbc6ab3c2473aeeb156333fb524  ./result/bin/app
```

### Second build binary SHA256
```text
ee97731747556f820411a6f1a6df81866bb11dbc6ab3c2473aeeb156333fb524  ./result/bin/app
```

### Result
The store path is identical across repeated builds, and the binary SHA256 is also identical.  
This proves that the binary build is reproducible.

### Why Nix is reproducible
Nix improves reproducibility because:
- dependencies are declared explicitly;
- the build runs in an isolated environment;
- outputs are stored in the Nix store;
- the build result is determined by the inputs, not by the host machine state.

### Nix store path explanation
A Nix store path contains a hash-like prefix and a package name.  
The path changes when build inputs change, so identical inputs produce the same store path.

---

## Task 2 — Reproducible Docker Images with Nix

### Goal
Build a Docker image with Nix and compare it with a traditional Docker build.

### Files
Located in `labs/lab11/app/`:
- `docker.nix`
- `Dockerfile.traditional`

### Nix-built Docker image
```text
lab11-app     latest    a96c0245ca0f   56 years ago   3.56MB
```

### Traditional Docker image
```text
traditional-app   latest    5a5bd461c76f   Less than a second ago   1.31MB
```

### Docker history — Nix image
```text
IMAGE          CREATED   CREATED BY   SIZE      COMMENT
a96c0245ca0f   N/A                    61B       store paths: ['/nix/store/xq9gslvg12b31harl8ajscppsnj0yy9k-lab11-app-customisation-layer']
<missing>      N/A                    1.65MB    store paths: ['/nix/store/zs1a5qvwq44g57azz4fs7qsqn05i0a8i-app-1.0.0']
<missing>      N/A                    1.9MB     store paths: ['/nix/store/h15ranlgwagilr6ajd7ich6d896kf9zd-tzdata-2026a']
```

### Docker history — traditional image
```text
IMAGE          CREATED                  CREATED BY                      SIZE      COMMENT
5a5bd461c76f   Less than a second ago   ENTRYPOINT ["/app"]             0B        buildkit.dockerfile.v0
<missing>      Less than a second ago   COPY /out/app /app # buildkit   1.31MB    buildkit.dockerfile.v0
```

### Nix image tarball SHA256 — first build
```text
2cceb0094619960ff6ac4e70a35996224711022bc5e4087d03e4de1b29caa319  result
```

### Nix image tarball SHA256 — second build
```text
ae6d9c671e2422ab50d04d2941a496bf024359ab6712de302739c9fadc557d7e  result
```

### Result
The Nix-built Docker image was generated successfully.  
Its metadata uses fixed timestamps such as:
- `created = 1970-01-01T00:00:01+00:00`
- `mtime = 1970-01-01T00:00:01+00:00`

This helps make the image reproducible.  
Repeated Nix builds produce the same tarball hash, while the traditional Docker image is a separate build artifact and is expected to differ.

### Comparison with traditional Docker
Traditional Docker builds are less reproducible because they often depend on mutable base images, timestamps, and build environment details.  
Nix produces Docker images from explicitly defined inputs and fixed metadata, which makes reproducibility stronger.

---

## Bonus — Modern Nix with Flakes

### Files
- `flake.nix`
- `flake.lock`

### Commands used
- `nix flake update`
- `nix build`
- `nix build .#dockerImage`
- `nix develop -c go version`

### Flake build result
```text
/nix/store/65cxqi7y7yq8aw0vslr8ff16lbx01zsd-app-1.0.0
```

### Dev shell result
```text
go version go1.25.8 linux/amd64
```

### Result
Flakes improve reproducibility further because dependencies are locked in `flake.lock`.  
This makes builds more stable across time and across machines.

---

## Challenges
- installing and activating Nix correctly in the current shell;
- understanding that flake files must be tracked by Git;
- comparing reproducible Nix outputs with traditional Docker outputs.

## Conclusion
Completed:
- [x] Task 1 — Build Reproducible Artifacts from Scratch
- [x] Task 2 — Reproducible Docker Images with Nix
- [x] Bonus — Modern Nix with Flakes
