# 1

1.1
```
nix --version
nix (Nix) 2.34.6
```

1.2
```
cat default.nix
{ pkgs ? import <nixpkgs> {} }:

pkgs.buildGoModule {
  pname = "hello";
  version = "1.0.0";

  src = ./.;

  vendorHash = null;
}
```

1.3
```
readlink result
/nix/store/hzyvkmznaxxzvxw72mnagjaaqlbkfaj9-hello-1.0.0

rm result
nix-build
readlink result
/nix/store/hzyvkmznaxxzvxw72mnagjaaqlbkfaj9-hello-1.0.0
/nix/store/hzyvkmznaxxzvxw72mnagjaaqlbkfaj9-hello-1.0.0
```

1.4
```
sha256sum ./result/bin/hello
d55a047be087aed743c14fd8409a77a9280de82aa93eecb654229a7b504639f9  ./result/bin/hello
```

1.5 Docker builds are not reproducible because they embed timestamps, depend on network-fetched dependencies that can change over time, and lack hermetic sandboxing, meaning the same Dockerfile can produce different binary hashes when built on different days or machines.

1.6 Nix builds are reproducible due to content-addressed storage (where the store path hash includes every input from source code to compiler flags), hermetic sandboxed environments that eliminate network and timestamp variability, and purely functional evaluation that guarantees identical inputs always produce identical outputs.

1.7 The Nix store path /nix/store/hzyvkmznaxxzvxw72mnagjaaqlbkfaj9-hello-1.0.0 consists of the fixed /nix/store directory, a 32-character base32 hash (hzyvkmznaxxzvxw72mnagjaaqlbkfaj9) derived from all build inputs, and a human-readable name (hello-1.0.0) that identifies the package and version.

# 2

2.1 
```
cat docker.nix
{ pkgs ? import <nixpkgs> {} }:

let
  helloBinary = import ./default.nix { inherit pkgs; };
in
pkgs.dockerTools.buildLayeredImage {
  name = "hello-nix";
  tag = "reproducible";
  
  contents = [ helloBinary pkgs.coreutils pkgs.bash ];
  
  config = {
    Cmd = [ "/bin/hello" ];
    Env = [ "NIX_REPRODUCIBLE=1" ];
  };
}
```

2.2
```
docker images | grep -E "hello-nix|traditional-app"
traditional-app                                          latest            8483b04643cf   30 seconds ago   2.01MB
hello-nix                                                reproducible      19a46d6e6a51   56 years ago     65.6MB
```

2.3
```
sha256sum result
36e7417fa2ede7676e6e513fbda988ca537e1c5b5c69710d5df43ea04755fe19  result
rm result && nix-build docker.nix && sha256sum result
/nix/store/nhd743r177zyjfkqfzy992xcg709qbh3-hello-nix.tar.gz
36e7417fa2ede7676e6e513fbda988ca537e1c5b5c69710d5df43ea04755fe19  result
```

2.4
```
docker history hello-nix:reproducible
IMAGE          CREATED   CREATED BY   SIZE      COMMENT
19a46d6e6a51   N/A                    8.97kB    store paths: ['/nix/store/rn0briz97hyvqxaxiqb5xq25w7zmq5r6-hello-nix-customisation-layer']
<missing>      N/A                    1.69MB    store paths: ['/nix/store/74sind1d6vf2bfwd7yklg8chsvzqxmmq-coreutils-9.10']
<missing>      N/A                    7.38MB    store paths: ['/nix/store/sfvyavxai6qvzmv9p9x6mp4wwdz4v41m-bash-interactive-5.3p9']
<missing>      N/A                    781kB     store paths: ['/nix/store/dlr3cc27i1mjkqcm9jlp5bjmb0n57q01-gmp-with-cxx-6.3.0']
<missing>      N/A                    10.3MB    store paths: ['/nix/store/ab3753m6i7isgvzphlar0a8xb84gl96i-gcc-15.2.0-lib']
<missing>      N/A                    505kB     store paths: ['/nix/store/qq90p0xx02ydaqv2gv28mx4qx2vk98fq-readline-8.3p3']
<missing>      N/A                    3.3MB     store paths: ['/nix/store/4zmr3iw5s719y5zz7h2dnym67x2i6n23-ncurses-6.6']
<missing>      N/A                    122kB     store paths: ['/nix/store/4sabfgpxkbv6w3mvk0wil50vdi37m9r8-acl-2.3.2']
<missing>      N/A                    85.1kB    store paths: ['/nix/store/p2yk6q3bhcz1d0wlmk907ysj4l95ak7y-attr-2.5.2']
<missing>      N/A                    34.9MB    store paths: ['/nix/store/jms7zxzm7w1whczwny5m3gkgdjghmi2r-glibc-2.42-51']
<missing>      N/A                    1.79MB    store paths: ['/nix/store/9j6vxkjpkdw8q4vyzgd32lif12xr1ja4-hello-1.0.0']
<missing>      N/A                    362kB     store paths: ['/nix/store/1ga782ml07vy0h503ac4cin0h8d7q6yh-libidn2-2.3.8']
<missing>      N/A                    1.9MB     store paths: ['/nix/store/h15ranlgwagilr6ajd7ich6d896kf9zd-tzdata-2026a']
<missing>      N/A                    2.08MB    store paths: ['/nix/store/p7jg95rzvfalb95k3mskk0jqxc9d724n-libunistring-1.4.1']
<missing>      N/A                    197kB     store paths: ['/nix/store/hbnbbbx1n96v1waiiaid9fmg4li4i1kp-gcc-15.2.0-libgcc']
<missing>      N/A                    197kB     store paths: ['/nix/store/vpxblivamvic1p5r5zny934jvg33m50r-xgcc-15.2.0-libgcc']
```
```
docker history traditional-app:latest
IMAGE          CREATED          CREATED BY                      SIZE      COMMENT
8483b04643cf   10 minutes ago   ENTRYPOINT ["/app"]             0B        buildkit.dockerfile.v0
<missing>      10 minutes ago   COPY /app/app /app # buildkit   2.01MB    buildkit.dockerfile.v0
```

2.5
Nix-built images are smaller because they avoid duplicate libraries and strip unnecessary files using the Nix store's hardlinking, and more reproducible because they never embed timestamps (unlike Docker's created = "now") and pin every dependency by cryptographic hash instead of using mutable tags like latest.

2.6
Nix images use buildLayeredImage to create many small, cache-optimized layers where each layer corresponds to a single store path, while traditional Docker images have one large layer containing all files with embedded timestamps.
```
docker inspect hello-nix:reproducible | grep -A 20 "Layers"
            "Layers": [
                "sha256:4d0baca456df7775961a5c7da602937de8a581938f59470e2703489cf9d55a18",
                "sha256:ba3238764a6a7e707726f4287447ef693f0c2cded460d7f3cae8131656269e7d",
                "sha256:3e8a64ab6b98fd834b5abf822a6641f5939d193e0a183c3754cd7578260a026a",
                "sha256:686cfd5739057a778e138d4e2d68a0c4f5641d3ade27dbbbd0dbd563fbe59a56",
                "sha256:090d18caa919c0813e75f679df52c77e578998d68ac47d9556b59c3f862fc7f4",
                "sha256:ffae2277d8de6a0c69ee3965299fd85b881ecbb08a29d02c70927fd015aeddb4",
                "sha256:73e59db2596b47fb890bd30712d54948501487d064f018e63d52d31225f3e656",
                "sha256:03024442ed5e42087f4ae615d4ce83d930db651430facfdedc468a0b187cc49d",
                "sha256:b1f98522c034b301a04a48286aa9f0a1deb16ac3338255bf3d3a390769ac18f1",
                "sha256:a841feaf52bc3d7ca0bdf80afd3bab131d3c43bdf77ca70407166ca12d8f6e0a",
                "sha256:a704927ce1cd394c403cde58ec1c1a10b97a3b14fe2b96db771685f84e38317a",
                "sha256:6edaba3a828534a51cb91624463887b8040edca0268587bfb671cc681bbfcde3",
                "sha256:d5144fa09f340e56acdd704e6df4ca1d7574a37e4e76698d16ad561f26394769",
                "sha256:5c1007d227e6591811cd04806a11c704d7656c43c9b6610e42aa7924b70d3506",
                "sha256:267c0484ace3947ce89ffe0a70403009db7c70d822e8eac8fe0a86c3d0448f90",
                "sha256:3dc7c12bf9c4b0122fd111b85a163eff5fd780308e728279d2281a72221d2315"
            ]
        },
        "Metadata": {
            "LastTagTime": "0001-01-01T00:00:00Z"
```
```
docker inspect traditional-app:latest | grep -A 20 "Layers"
            "Layers": [
                "sha256:8c444404909a4afe2c9b8c7e6cb4b46c3c08b4ce617aac38a33bb00a320fcde2"
            ]
        },
        "Metadata": {
            "LastTagTime": "2026-04-17T20:22:35.823527994+03:00"
        }
    }
]
```

2.7 Content-addressable Docker images enable perfect cache invalidation (changing one dependency only rebuilds that layer), verifiable supply chain security, and reproducible deployments across any infrastructure without "it works on my machine" issues.