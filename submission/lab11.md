# Lab 11 submission 

### `flake.nix`:

```
{
  description = "QuickNotes Reproducible Build";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: 
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      pkgsFor = system: import nixpkgs { inherit system; };
    in {
      packages = forAllSystems (system: 
        let
          pkgs = pkgsFor system;
          
          quicknotes = pkgs.buildGoModule {
            pname = "quicknotes";
            version = "1.0.0";
            src = ./app;
            
            env = {
                CGO_ENABLED = "0";
            };  
            vendorHash = null;
            
            ldflags = [ "-s" "-w" ];
          };

          docker = pkgs.dockerTools.buildImage {
            name = "quicknotes-image";
            tag = "latest";
            copyToRoot = [ quicknotes ];
            
            config = {
              Entrypoint = [ "${quicknotes}/bin/quicknotes" ]; 
              ExposedPorts = {
                "8080/tcp" = {};
              };
              # 4. Запуск от nonroot пользователя
              User = "65532:65532";
            };
          };
        in {
          inherit quicknotes docker;
          default = quicknotes;
        }
      );

      devShells = forAllSystems (system: 
        let pkgs = pkgsFor system;
        in {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [ go gopls golangci-lint ];
          };
        }
      );
    };
}
```

### In original enviroment:
```
nix build .#quicknotes
nix-store --query --hash $(readlink result)
warning: Git tree '/home/long1tail/DevOps-Intro' has uncommitted changes
warning: creating lock file "/home/long1tail/DevOps-Intro/flake.lock": 
• Added input 'nixpkgs':
    'github:NixOS/nixpkgs/e7a3ca8' (2026-07-11)
sha256:1ncrpavy7j4zdgwb81j4m3dhi93zq6gg3s65g4gdwv5y0agmpxj8
```

### In docker container:
```
docker run --rm -it -v "$PWD:/repo:ro" -w /tmp nixos/nix bash
Unable to find image 'nixos/nix:latest' locally
latest: Pulling from nixos/nix
5bbb9a1560e0: Pulling fs layer 
cecc6f2dd909: Pulling fs layer 
d914e1069166: Pulling fs layer
7e843bf6f79c: Pulling fs layer 
5d01129dd971: Pulling fs layer 
e41f239e48de: Pulling fs layer 
1391a42a7d4f: Pulling fs layer 
8e4b6dfa6e74: Pulling fs layer
49d8c548e753: Pulling fs layer 
df46668aac03: Pulling fs layer
086f9eba900c: Pulling fs layer 
d752c5b2c4af: Pulling fs layer 
60e24da2e82c: Pulling fs layer 
f7bc1fe11449: Pulling fs layer 
a73f74f657e8: Pulling fs layer 
fcbdb9a1235c: Pulling fs layer 
90d58ab27179: Pulling fs layer 
971d76ab5fcf: Pulling fs layer 
d1544a7f4969: Pulling fs layer 
a83d86eee742: Pulling fs layer 
c5b06bdc9442: Pulling fs layer 
14b338d785e5: Pulling fs layer
4f3f654ea1b7: Pulling fs layer 
53c8bca101d6: Pulling fs layer 
0dd4d40dac56: Pulling fs layer 
ba31dae40b68: Pulling fs layer 
7973ce6f4096: Pulling fs layer 
545b08d3bfe0: Pulling fs layer 
5bc3565afc1e: Pulling fs layer 
b25bd4a36b50: Pulling fs layer 
37b67f6e7070: Pulling fs layer 
4614463a6759: Pulling fs layer 
fb154c30f01d: Pulling fs layer 
c4cad49100cb: Pulling fs layer 
f8d2d3417a08: Pulling fs layer
de98d18d9404: Pulling fs layer 
803717e0bdbe: Pulling fs layer 
683ddd906443: Pulling fs layer 
9af268ad45df: Pulling fs layer 
8c439df9b30d: Pulling fs layer 
12e27434d81f: Pulling fs layer 
d41705eba125: Pulling fs layer 
ca9906430cbf: Pulling fs layer 
f8636065ef23: Pulling fs layer
7dda5e9cf49a: Pulling fs layer 
2d06e7068852: Pulling fs layer 
10c71fdc149b: Pulling fs layer
f0b6b057fde7: Pulling fs layer 
20a845de7af2: Pulling fs layer 
5d01129dd971: Pull complete
47096b4a41f2: Pull complete 
38fa065681ed: Pull complete 
ce4f9d5ac9dd: Pull complete 
85e9bbece85f: Pull complete 
a16d85b13fa9: Pull complete 
afb62bb10e11: Pull complete 
43c65ca7c55d: Pull complete 
9e12979398cd: Pull complete 
e5f91e20fd83: Pull complete
8c01feded0e5: Pull complete 
f7df9a7ac406: Pull complete 
712563bf7b38: Pull complete 
5489a32a9822: Pull complete 
1780ee13d503: Pull complete 
2a2ab1dc050d: Pull complete 
d37f1bfc52b2: Pull complete 
fa77348d693e: Pull complete
f7e9b8cee226: Pull complete 
df93d7b893ef: Pull complete 
Digest: sha256:377d4887aca98f0dfa12971c1ea6d6a625a435d8b610d4c95a436843da6fbfd1
Status: Downloaded newer image for nixos/nix:latest


bash-5.3# cp -r /repo ./quicknotes
cd quicknotes

bash-5.3# mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" > ~/.config/nix/nix.conf

bash-5.3# nix build .#quicknotes
warning: Git tree '/tmp/quicknotes' is dirty

bash-5.3# nix-store --query --hash $(readlink result)
sha256:1ncrpavy7j4zdgwb81j4m3dhi93zq6gg3s65g4gdwv5y0agmpxj8
```

### Health check:

```
./result/bin/quicknotes & curl http://localhost:8080/health
{"notes":4,"status":"ok"}
```

### reproducibility:
##### Enviroment A:
```
nix build .#docker
sha256sum result
warning: Git tree '/home/long1tail/DevOps-Intro' has uncommitted changes
411873fe4ca281ed950c2c890852c2150310b4323cd1e3942e34baf52d8846ce  result
```

##### Enviroment B:
```
nix build .#docker
sha256sum result
warning: Git tree '/home/long1tail/DevOps-Intro' has uncommitted changes
411873fe4ca281ed950c2c890852c2150310b4323cd1e3942e34baf52d8846ce  result
```

### Questions.

- a. Usual `go build` includes route file of file system, time stamps, build ID. This values are unique for every build. Therefore, each build produced not bit-identical outputs.
- b. `vendorHash` - SHA256 of `vendor/` directory, created during Go-mudules installation. If set `null` - Nix would forbid download during build and require all dependencies to be commited
- c. `flake.lock` strictly pins the commit hashes of all inputs (e.g., the exact version of the `nixpkgs` repository). If you delete it, Nix will fetch the latest commit from the `nixos-24.11` branch, where compiler and system library versions might differ, breaking reproducibility across machines.
- d. `buildGoModule` is the modern standard in `nixpkgs` for building Go applications using Go Modules. `buildGoApplication` is not a standard core function in `nixpkgs`. For QuickNotes, `buildGoModule` should be used since the project relies on a standard `go.mod` file.
- e. `docker build` reads files from the host system (preserving their `mtime` timestamps), downloads fresh packages (e.g., via `apt-get`, where versions constantly change), and saves the creation timestamp for each individual layer.
- f. With a deterministic build, an auditor can take the source code, build it themselves, and obtain a bit-for-bit identical image hash. This proves that no backdoors were injected into the compiled image during the CI pipeline execution (preventing supply chain attacks).
- g. The main trade-off of Nix is its steep learning curve, domain-specific language, and the need to rewrite standard Dockerfiles into Nix expressions. `docker build` remains the industry standard due to its ease of use, familiar syntax, and broad compatibility.