# Lab 11 Submission

## Task 1 — Reproducible Go Build via Nix Flake

### Implementation

The repository uses `buildGoModule` because QuickNotes is a Go module and this
builder is provided directly by nixpkgs. It handles the Go build, test, module
vendoring, and reproducibility settings without requiring another flake input or
generated dependency manifest.

The flake exposes both `packages.x86_64-linux.quicknotes` and
`packages.x86_64-linux.default`. It also provides a default development shell
containing Go, `gopls`, and `golangci-lint`.

```nix
{
  description = "Reproducible Nix build for QuickNotes";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

  outputs = { nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      quicknotes = pkgs.buildGoModule {
        pname = "quicknotes";
        version = "0.1.0";

        src = ./app;

        vendorHash = "sha256-6nOwg48X8bfUliKtHbMMVOoi4aZ3coyYClMWGiYPrYc=";

        # QuickNotes has no external Go modules. This deterministic marker
        # allows the exercise to demonstrate a non-null vendor hash.
        overrideModAttrs = _final: _previous: {
          postBuild = ''
            printf '%s\n' \
              "QuickNotes has no external Go modules." \
              > vendor/NO_EXTERNAL_DEPENDENCIES
          '';
        };

        env.CGO_ENABLED = "0";

        ldflags = [
          "-s"
          "-w"
        ];
      };
    in
    {
      packages.${system} = {
        inherit quicknotes;
        default = quicknotes;
      };

      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          go
          gopls
          golangci-lint
        ];
      };
    };
}
```

The generated lock file is committed at [flake.lock](../flake.lock). It pins
nixpkgs to revision
`b6018f87da91d19d0ab4cf979885689b469cdd41` with NAR hash
`sha256-twXPFqFsrrY5r28Zh7Homgcp2gUMBgQ6WDS98Q/3xFI=`.

### Flake outputs

Command:

```bash
nix flake show
```

Relevant output:

```text
git+file:///home/mostafa/git_repos/DevOps-Intro
├───devShells
│   └───x86_64-linux
│       └───default: development environment 'nix-shell'
└───packages
    └───x86_64-linux
        ├───default: package 'quicknotes-0.1.0'
        └───quicknotes: package 'quicknotes-0.1.0'
```

### Vendor hash discovery

The first build used `pkgs.lib.fakeHash` and failed as expected:

```text
quicknotes> go: no dependencies to vendor
error: hash mismatch in fixed-output derivation
         specified: sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=
            got:    sha256-6nOwg48X8bfUliKtHbMMVOoi4aZ3coyYClMWGiYPrYc=
```

The `got` value was copied into `vendorHash`, after which the build succeeded.

QuickNotes currently has no external Go modules. The flake therefore adds a
deterministic `NO_EXTERNAL_DEPENDENCIES` marker to the generated vendor output.
This permits the lab's required non-null vendor hash to be demonstrated without
adding an unnecessary application dependency.

### Successful build

Command:

```bash
nix build -L .#quicknotes
```

Build excerpt:

```text
quicknotes> Running phase: unpackPhase
quicknotes> source root is app
quicknotes> Running phase: configurePhase
quicknotes> Running phase: buildPhase
quicknotes> Building subPackage .
quicknotes> Running phase: checkPhase
quicknotes> ok          quicknotes      0.017s
quicknotes> Running phase: installPhase
quicknotes> Running phase: fixupPhase
quicknotes> patchelf: cannot find section '.dynamic'. The input file is most likely statically linked
quicknotes> stripping (with command strip and flags -S -p) in /nix/store/y3pb43jjgik7y8mlhh3mlbz76h0dr8w3-quicknotes-0.1.0/bin
```

The `patchelf` message is expected for this build because `CGO_ENABLED` is zero
and the executable is statically linked. The resulting binary was also stripped.

The default package alias built successfully with:

```bash
nix build .#default
```

### Development shell and tests

Command:

```bash
nix develop -c sh -c 'cd app && go test ./...'
```

Output:

```text
ok      quicknotes      0.167s
```

Development-tool versions were checked with:

```bash
nix develop -c sh -c '
  go version
  gopls version
  golangci-lint version
'
```

Output:

```text
go version go1.25.10 linux/amd64
golang.org/x/tools/gopls v0.20.0
golangci-lint has version 2.6.2 built with go1.25.10 from v2.6.2 on 1970-01-01T00:00:00Z
```

`nix flake check` and `git diff --check` both completed without errors.

### Runtime verification

The Nix-built executable was run with temporary data storage and the repository
seed file:

```bash
tmpdir=$(mktemp -d)

DATA_PATH="$tmpdir/notes.json" \
SEED_PATH="$PWD/app/seed.json" \
ADDR=:18080 \
./result/bin/quicknotes > /tmp/quicknotes-lab11.log 2>&1 &

pid=$!
sleep 1
curl -fsS http://localhost:18080/health
kill -TERM "$pid"
wait "$pid"
rm -rf "$tmpdir"
```

Health response:

```json
{"notes":4,"status":"ok"}
```

Application log:

```text
2026/07/14 18:14:01 quicknotes listening on :18080 (notes loaded: 4)
2026/07/14 18:14:18 shutting down
```

### Reproducibility proof

Both environments built Git commit
`631a6c2038bc50f6062cc89f249b1b34f2d6f5c2`.

#### Environment A

- Machine: `aorus-AORUS-15-BSF`
- Architecture: `x86_64`
- Store path:
  `/nix/store/8v9s78icgfc48qzhm5542a0s7v5fc8ar-quicknotes-0.1.0`

Commands:

```bash
nix build .#quicknotes
nix-store --query --hash "$(readlink -f result)"
```

Output:

```text
sha256:1hv80kblj0zqcz82z0wihvxz63kylgwkqqgv5naykf0ar4f26w8k
```

#### Environment B

- Machine: `pc`
- Checkout commit:
  `631a6c2038bc50f6062cc89f249b1b34f2d6f5c2`

Commands:

```bash
nix build .#quicknotes
nix-store --query --hash "$(readlink -f result)"
```

Output:

```text
sha256:1hv80kblj0zqcz82z0wihvxz63kylgwkqqgv5naykf0ar4f26w8k
```

The two independent builds produced identical Nix store content hashes.

### Design questions

#### a. Why does `go build` not guarantee bit-identical outputs on two machines?

The Go toolchain is designed to be deterministic for equivalent inputs, but a
plain `go build` command does not pin all of those inputs. Two machines may use
different Go compiler or standard-library versions, dependency resolutions,
build flags, environment variables, source paths, VCS dirty-state metadata, or
CGO compilers and system libraries. Absolute build paths can also be embedded
unless `-trimpath` is used, and differing inputs are reflected in Go build IDs.
Timestamps may additionally enter through code generation, packaging, or other
surrounding build steps.

Nix makes the complete build environment part of the derivation. The locked
nixpkgs revision selects the toolchain, `buildGoModule` applies reproducibility
settings such as trimmed paths and an empty build ID, and `CGO_ENABLED = 0`
removes dependence on a host C toolchain and host libraries.

#### b. What does `vendorHash` cover, and what happens when it is `null`?

`vendorHash` is an SRI SHA-256 hash of the Nix fixed-output derivation containing
the vendored Go module dependency tree. It verifies the dependency material
produced from the module metadata; it is not a hash of the QuickNotes source or
the final executable. If the dependency tree changes, Nix reports a hash
mismatch and requires the declared value to be reviewed and updated.

With `vendorHash = null`, `buildGoModule` does not create the separate
`goModules` fixed-output derivation. This setting is appropriate when a project
has no external dependencies or already contains its vendor directory. In this
repository the natural setting would be `null` because QuickNotes uses only the
standard library. The deterministic marker in this flake exists specifically to
satisfy the lab requirement to demonstrate obtaining and pinning a non-null
vendor hash without introducing an unnecessary production dependency.

#### c. Why is `flake.lock` essential for reproducibility?

The `nixos-25.11` reference in `flake.nix` names a moving release branch, not an
immutable commit. `flake.lock` records the exact nixpkgs revision and its NAR
hash, along with the locked input graph. This pins the Go compiler, Nix build
helpers, development tools, and other packages selected from nixpkgs.

If `flake.lock` is deleted before the second build, Nix resolves the branch
again and generates a new lock. If the branch has advanced, the new checkout may
contain different toolchain versions or build logic, which changes the
derivation, store path, and potentially the output bytes. Committing the lock
file ensures both machines evaluate the same external inputs.

#### d. What is the difference between `buildGoModule` and `buildGoApplication`, and which is appropriate here?

`buildGoModule` is the standard nixpkgs Go-module builder. It commonly uses one
fixed-output vendoring derivation protected by `vendorHash`, then builds and
tests the program in the Nix sandbox. This provides a small and direct flake for
a conventional project containing `go.mod`.

The commonly used `buildGoApplication` workflow is provided by `gomod2nix`. It
uses a generated `gomod2nix.toml` manifest with dependency information and
per-module hashes. That can offer more granular dependency fetching and caching,
but it requires the additional gomod2nix tooling, flake input, and generated
manifest.

`buildGoModule` was selected for QuickNotes because the application is a simple
Go module, uses only the standard library, and does not benefit from the extra
gomod2nix workflow.
