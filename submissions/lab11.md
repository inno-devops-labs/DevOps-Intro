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
          
          created = 
            let
              envEpoch = builtins.getEnv "SOURCE_DATE_EPOCH";
            in 
              if envEpoch != "" then envEpoch else "1970-01-01T00:00:01Z"; 

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

### Bonus: CI
[Link](../.github/workflows/nix-repro.yml)

### Bonus: Successful run
[Workflow run](https://github.com/arsenez2006/DevOps-Intro/actions/runs/29443235411)\
Log:
```log
2026-07-15T19:07:34.6907937Z Current runner version: '2.335.1'
2026-07-15T19:07:34.6935015Z ##[group]Runner Image Provisioner
2026-07-15T19:07:34.6935981Z Hosted Compute Agent
2026-07-15T19:07:34.6936596Z Version: 20260624.560
2026-07-15T19:07:34.6937221Z Commit: 925d229a51159bc391ae97e54a2dd1fe20af789d
2026-07-15T19:07:34.6938022Z Build Date: 2026-06-24T18:26:47Z
2026-07-15T19:07:34.6938699Z Worker ID: {501a14b5-75e7-4d76-aa9f-547d048b9b14}
2026-07-15T19:07:34.6939385Z Azure Region: westus
2026-07-15T19:07:34.6940019Z ##[endgroup]
2026-07-15T19:07:34.6941866Z ##[group]Operating System
2026-07-15T19:07:34.6942624Z Ubuntu
2026-07-15T19:07:34.6943517Z 24.04.4
2026-07-15T19:07:34.6944242Z LTS
2026-07-15T19:07:34.6944851Z ##[endgroup]
2026-07-15T19:07:34.6945414Z ##[group]Runner Image
2026-07-15T19:07:34.6946004Z Image: ubuntu-24.04
2026-07-15T19:07:34.6946726Z Version: 20260705.232.1
2026-07-15T19:07:34.6947992Z Included Software: https://github.com/actions/runner-images/blob/ubuntu24/20260705.232/images/ubuntu/Ubuntu2404-Readme.md
2026-07-15T19:07:34.6949586Z Image Release: https://github.com/actions/runner-images/releases/tag/ubuntu24%2F20260705.232
2026-07-15T19:07:34.6950512Z ##[endgroup]
2026-07-15T19:07:34.6951784Z ##[group]GITHUB_TOKEN Permissions
2026-07-15T19:07:34.6954596Z Contents: read
2026-07-15T19:07:34.6955330Z Metadata: read
2026-07-15T19:07:34.6955894Z Packages: read
2026-07-15T19:07:34.6956549Z ##[endgroup]
2026-07-15T19:07:34.6959053Z Secret source: Actions
2026-07-15T19:07:34.6960062Z Prepare workflow directory
2026-07-15T19:07:34.7321652Z Prepare all required actions
2026-07-15T19:07:34.7422768Z Complete job name: verify-reproducibility
2026-07-15T19:07:34.8247605Z ##[group]Run HASH_A="0f09ae87be61dcb999ad1eba1f882210e0ee6c8b1e04c03116e8065c93b89720"
2026-07-15T19:07:34.8249129Z [36;1mHASH_A="0f09ae87be61dcb999ad1eba1f882210e0ee6c8b1e04c03116e8065c93b89720"[0m
2026-07-15T19:07:34.8250271Z [36;1mHASH_B="0f09ae87be61dcb999ad1eba1f882210e0ee6c8b1e04c03116e8065c93b89720"[0m
2026-07-15T19:07:34.8251259Z [36;1m[0m
2026-07-15T19:07:34.8251999Z [36;1mecho "Digest from Environment A: $HASH_A"[0m
2026-07-15T19:07:34.8252833Z [36;1mecho "Digest from Environment B: $HASH_B"[0m
2026-07-15T19:07:34.8253776Z [36;1m[0m
2026-07-15T19:07:34.8254310Z [36;1mif [ "$HASH_A" != "$HASH_B" ]; then[0m
2026-07-15T19:07:34.8255199Z [36;1m  echo "::error::Reproducibility failed! Digests do not match."[0m
2026-07-15T19:07:34.8256019Z [36;1m  exit 1[0m
2026-07-15T19:07:34.8256563Z [36;1mfi[0m
2026-07-15T19:07:34.8257093Z [36;1mecho "Success."[0m
2026-07-15T19:07:34.8931535Z shell: /usr/bin/bash -e {0}
2026-07-15T19:07:34.8933483Z ##[endgroup]
2026-07-15T19:07:34.9202133Z Digest from Environment A: 0f09ae87be61dcb999ad1eba1f882210e0ee6c8b1e04c03116e8065c93b89720
2026-07-15T19:07:34.9205062Z Digest from Environment B: 0f09ae87be61dcb999ad1eba1f882210e0ee6c8b1e04c03116e8065c93b89720
2026-07-15T19:07:34.9206877Z Success.
2026-07-15T19:07:34.9366404Z Cleaning up orphan processes
```

### Bonus: Failed run
[Link](https://github.com/arsenez2006/DevOps-Intro/actions/runs/29444597150)\
Log:
```log
2026-07-15T19:28:55.3530430Z Current runner version: '2.335.1'
2026-07-15T19:28:55.3554079Z ##[group]Runner Image Provisioner
2026-07-15T19:28:55.3554858Z Hosted Compute Agent
2026-07-15T19:28:55.3555370Z Version: 20260707.563
2026-07-15T19:28:55.3555911Z Commit: 02667638d2b423fbc733a8e32a88b44996a3ba6e
2026-07-15T19:28:55.3556514Z Build Date: 2026-07-07T19:33:50Z
2026-07-15T19:28:55.3557058Z Worker ID: {c54696be-faa5-427b-8739-7260a72d8432}
2026-07-15T19:28:55.3557677Z Azure Region: westus3
2026-07-15T19:28:55.3558173Z ##[endgroup]
2026-07-15T19:28:55.3559529Z ##[group]Operating System
2026-07-15T19:28:55.3560046Z Ubuntu
2026-07-15T19:28:55.3560473Z 24.04.4
2026-07-15T19:28:55.3560918Z LTS
2026-07-15T19:28:55.3561374Z ##[endgroup]
2026-07-15T19:28:55.3561824Z ##[group]Runner Image
2026-07-15T19:28:55.3562356Z Image: ubuntu-24.04
2026-07-15T19:28:55.3562878Z Version: 20260714.240.1
2026-07-15T19:28:55.3564165Z Included Software: https://github.com/actions/runner-images/blob/ubuntu24/20260714.240/images/ubuntu/Ubuntu2404-Readme.md
2026-07-15T19:28:55.3565529Z Image Release: https://github.com/actions/runner-images/releases/tag/ubuntu24%2F20260714.240
2026-07-15T19:28:55.3566412Z ##[endgroup]
2026-07-15T19:28:55.3567461Z ##[group]GITHUB_TOKEN Permissions
2026-07-15T19:28:55.3569891Z Contents: read
2026-07-15T19:28:55.3570450Z Metadata: read
2026-07-15T19:28:55.3570983Z Packages: read
2026-07-15T19:28:55.3571499Z ##[endgroup]
2026-07-15T19:28:55.3573887Z Secret source: Actions
2026-07-15T19:28:55.3574877Z Prepare workflow directory
2026-07-15T19:28:55.3860231Z Prepare all required actions
2026-07-15T19:28:55.3950767Z Complete job name: verify-reproducibility
2026-07-15T19:28:55.4560940Z ##[group]Run HASH_A="0a747220abfd0fa6eeb3b121642321325a270748164914a4eb837cdfd64271d5"
2026-07-15T19:28:55.4562083Z [36;1mHASH_A="0a747220abfd0fa6eeb3b121642321325a270748164914a4eb837cdfd64271d5"[0m
2026-07-15T19:28:55.4563452Z [36;1mHASH_B="5843432148e863440b9e0a3fc3efc042692e57fc5f82100cd2d4557e0d3a65bb"[0m
2026-07-15T19:28:55.4564261Z [36;1m[0m
2026-07-15T19:28:55.4564942Z [36;1mecho "Digest from Environment A: $HASH_A"[0m
2026-07-15T19:28:55.4565838Z [36;1mecho "Digest from Environment B: $HASH_B"[0m
2026-07-15T19:28:55.4566452Z [36;1m[0m
2026-07-15T19:28:55.4566956Z [36;1mif [ "$HASH_A" != "$HASH_B" ]; then[0m
2026-07-15T19:28:55.4567680Z [36;1m  echo "::error::Reproducibility failed! Digests do not match."[0m
2026-07-15T19:28:55.4568370Z [36;1m  exit 1[0m
2026-07-15T19:28:55.4568891Z [36;1mfi[0m
2026-07-15T19:28:55.4569347Z [36;1mecho "Success."[0m
2026-07-15T19:28:55.6074276Z shell: /usr/bin/bash -e {0}
2026-07-15T19:28:55.6075099Z ##[endgroup]
2026-07-15T19:28:55.6361677Z Digest from Environment A: 0a747220abfd0fa6eeb3b121642321325a270748164914a4eb837cdfd64271d5
2026-07-15T19:28:55.6363495Z Digest from Environment B: 5843432148e863440b9e0a3fc3efc042692e57fc5f82100cd2d4557e0d3a65bb
2026-07-15T19:28:55.6399709Z ##[error]Reproducibility failed! Digests do not match.
2026-07-15T19:28:55.6415323Z ##[error]Process completed with exit code 1.
2026-07-15T19:28:55.6538210Z Cleaning up orphan processes
```