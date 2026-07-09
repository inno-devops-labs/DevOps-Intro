# Lab 11 — Reproducible Builds of QuickNotes with Nix

## Task 1 — Reproducible Go Build via Nix Flake

### flake.nix

See `flake.nix` at repo root (committed in this PR).

### Build log

```
$ nix build .#quicknotes
warning: creating lock file "flake.lock":
- Added input 'flake-utils'
- Added input 'nixpkgs' -> github:NixOS/nixpkgs/b6018f87da91d19d0ab4cf979885689b469cdd41 (2026-06-30)
```

### Proof of reproducibility — two independent environments

**Environment A — WSL2 (Ubuntu, host Nix store):**
```
$ nix-store --query --hash $(readlink result)
sha256:1hv80kblj0zqcz82z0wihvxz63kylgwkqqgv5naykf0ar4f26w8k
```

**Environment B — fresh nixos/nix Docker container (isolated Nix store, no shared cache with host):**
```
$ docker run --rm -it -v "$PWD:/repo" -w /repo nixos/nix bash
$ git config --global --add safe.directory /repo
$ nix --extra-experimental-features "nix-command flakes" build .#quicknotes
$ nix-store --query --hash $(readlink result)
sha256:1hv80kblj0zqcz82z0wihvxz63kylgwkqqgv5naykf0ar4f26w8k
```

**Result: identical hashes across two independent environments.**

### Binary runs and serves /health

```
$ ./result/bin/quicknotes &
2026/07/08 16:51:47 quicknotes listening on :8080 (notes loaded: 0)
$ curl -s http://localhost:8080/health
{"notes":0,"status":"ok"}
```

### Design questions

**a) Why doesn't `go build` produce bit-identical outputs on two machines, even from the same Git SHA?**

Plain `go build` embeds a build ID into the binary — a hash derived in part from the absolute
filesystem paths of `GOPATH`/`GOCACHE` and the working directory, which differ between machines.
Without `-trimpath`, debug info also embeds these absolute source paths verbatim. Module resolution
can also pull slightly different (but semver-compatible) transitive versions if `go.sum` isn't
fully pinned, though that's not an issue here since QuickNotes has no dependencies. Nix avoids all
of this by building inside a sandboxed, path-normalized environment and by explicitly passing
`-trimpath`.

**b) `vendorHash` is a SHA over what, exactly? What happens if you set `vendorHash = null;`?**

`vendorHash` is a fixed-output-derivation hash over the vendored Go module dependencies —
i.e., the content that `go mod vendor` would produce from `go.mod`/`go.sum`. It lets Nix fetch
those dependencies from the network once, then verify on every subsequent build that the fetched
content hasn't changed, without needing the network again. Setting `vendorHash = null;` tells Nix
there is nothing to vendor at all — valid here because QuickNotes' `go.mod` declares zero external
dependencies. If a real dependency existed and `vendorHash` were `null`, the build would fail with
a mismatch error showing the actual hash to paste in.

**c) `flake.lock` pins nixpkgs. Why is this the single most important file for reproducibility? What happens if you delete it before the second build?**

`flake.lock` records the exact commit of every flake input (nixpkgs, flake-utils) that was resolved
the first time the flake was built. Since nixpkgs is a moving target — the same branch reference
(`nixos-25.11`) points to a different commit every day as it receives updates — the lock file is
what turns "roughly this version of nixpkgs" into "exactly this commit, forever." Without it, two
people building the same flake reference on different days would silently get different compiler
and library versions. If deleted before a second build, Nix re-resolves the input to whatever the
latest commit on that branch is at that moment, which will very likely differ from the original
locked revision and can produce a different result.

**d) `buildGoModule` vs `buildGoApplication` — what's the difference? Which would you pick for QuickNotes and why?**

`buildGoModule` is nixpkgs' built-in, first-party function; it fetches all dependencies into one
vendor blob validated by a single `vendorHash`. `buildGoApplication` comes from the external
`gomod2nix` project and instead generates a per-dependency lock file, giving finer-grained caching
(only rebuild what changed) at the cost of requiring an extra external flake input and a
supplementary lockfile generator tool. For QuickNotes — a dependency-free module — the fine-grained
caching benefit of `buildGoApplication` is moot, so `buildGoModule` was chosen for simplicity and
because it needs no additional tooling beyond nixpkgs itself.
