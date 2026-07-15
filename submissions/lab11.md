# Lab 11 submission

### Flake
`flake.nix`:
```nix
{
  description = "QuickNotes";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, utils }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        quicknotes = pkgs.buildGoModule {
          pname = "quicknotes";
          version = "1.0.0";

          src = ./app;
          vendorHash = null; # vendorHash is null since quicknotes does not depend on external libraries
          env = {
            CGO_ENABLED = 0;
          };
          ldflags = [ "-s" "-w" ];
        };

        dockerImage = pkgs.dockerTools.buildImage {
          name = "quicknotes-oci";
          tag = "latest";
          
          created = "1970-01-01T00:00:01Z"; 

          copyToRoot = pkgs.buildEnv {
            name = "image-root";
            paths = [ quicknotes pkgs.cacert ];
            pathsToLink = [ "/bin" ];
          };

          config = {
            Entrypoint = [ "/bin/quicknotes" ];
            ExposedPorts = {
              "8080/tcp" = {};
            };
            User = "10001:10001";
          };
        };
      in
      {
        packages = {
          inherit quicknotes;
          docker = dockerImage;
          default = quicknotes;
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            go
            gopls
            golangci-lint
          ];
        };
      }
    );
}
```
[`flake.lock`](../flake.lock)

### Independant env check
* Machine A
```sh
$ nix-store --query --hash $(readlink result)                
sha256:0v3qblaw8xhrlz82q98n958svfiqdv1vd59990q8g506cs6x4cqy
```
* Machine B
```sh
$ nix-store --query --hash $(readlink result)                
sha256:0v3qblaw8xhrlz82q98n958svfiqdv1vd59990q8g506cs6x4cqy
```

### Docker image diggest reproducibility check
* Nix:
```sh
$ nix build .#docker
$ sha256sum result  
0f09ae87be61dcb999ad1eba1f882210e0ee6c8b1e04c03116e8065c93b89720  result
$ nix build .#docker
$ sha256sum result  
0f09ae87be61dcb999ad1eba1f882210e0ee6c8b1e04c03116e8065c93b89720  result
```

* Docker:
```sh
$ docker images --no-trunc qn-lab6
REPOSITORY   TAG       IMAGE ID                                                                  CREATED          SIZE
qn-lab6      run2      sha256:bcee8d94bdc0f3431e7179df82b2c9991b57a9f7a32a23b3a948f942d7bd21e4   18 seconds ago   5.93MB
qn-lab6      run1      sha256:e39421a67932931a5587d328c8a805ec4aa2c98d42b57d6f763343bdf0b353ec   25 seconds ago   5.93MB
```

### Image size comparison
* Docker:
```sh
docker images --no-trunc qn-lab6:run1
REPOSITORY   TAG       IMAGE ID                                                                  CREATED              SIZE
qn-lab6      run1      sha256:e39421a67932931a5587d328c8a805ec4aa2c98d42b57d6f763343bdf0b353ec   About a minute ago   5.93MB
```
* Nix:
```sh
$ docker images --no-trunc quicknotes-oci:latest
REPOSITORY       TAG       IMAGE ID                                                                  CREATED        SIZE
quicknotes-oci   latest    sha256:7fb52a5017714ca582063cf76145c39408e7b77e477487742c97ffc06eb75a99   56 years ago   8.71MB
```
