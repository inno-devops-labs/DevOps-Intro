# Lab10 submission

### Release workflow:

```
name: Release to GHCR

on:
  push:
    tags:
      - 'v*'

jobs:
  build-and-push:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write

    steps:
      - name: Checkout repository
        uses: actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0 # v7.0.0

      - name: Log in to the Container registry
        uses: docker/login-action@af1e73f918a031802d376d3c8bbc3fe56130a9b0 # v4.4.0
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Extract metadata (tags, labels) for Docker
        id: meta
        uses: docker/metadata-action@dc802804100637a589fabce1cb79ff13a1411302 # v6.2.0
        with:
          images: ghcr.io/${{ github.repository }}/quicknotes
          tags: |
            type=semver,pattern={{version}}
            type=raw,value=latest

      - name: Build and push Docker image
        uses: docker/build-push-action@53b7df96c91f9c12dcc8a07bcb9ccacbed38856a # v7.3.0
        with:
          context: ./app
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
```

### Registry URL:
https://ghcr.io/Long1Tail/DevOps-Intro/quicknotes:v0.1.0

### Successfull clean pull:
```
docker pull ghcr.io/long1tail/devops-intro/quicknotes:0.1.0
0.1.0: Pulling from long1tail/devops-intro/quicknotes
2507cd600e9f: Pull complete 
f5f1a349e172: Pull complete 
Digest: sha256:e9067010d468f0142e4ed907f539adf4d060957b8889b6a1bb9f9d3cfcbf5fe7
Status: Downloaded newer image for ghcr.io/long1tail/devops-intro/quicknotes:0.1.0
ghcr.io/long1tail/devops-intro/quicknotes:0.1.0
```

[green URL]('https://github.com/Long1Tail/DevOps-Intro/actions/runs/28883826581')

- a. `GITHUB_TOKEN` works well inside github ecosystem, meanwile OIDC is required fot other party autentification wothout sending secrets. Clud belives GitHub Actions token.
- b. Tag `:v0.1.0` gives guaranties of reproducibility and allows no changes. We always know what code will be executed. Tag `:latest` exists for user's comfort
- c. Principle of Least Privilege. If token will leak, with `packages: write` attacker will be able only to ruin image registry, meanwhile `write:all` would allow to change code, allow PR and release malware from developer's name.

[Space URL]('https://huggingface.co/spaces/Long1Tail/quicknotes')

Space Dockerfile: 
```
FROM ghcr.io/long1tail/devops-intro/quicknotes:v0.1.0
```

```curl -v https://huggingface.co/sp
aces/Long1Tail/quicknotes/health`
< HTTP/2 200
< content-type: application/json
{"notes":4,"status":"ok"}
```

### "Warm" latency:
```
$ for i in $(seq 1 5); do
    curl -w '%{time_total}\n' -o /dev/null -s \
      https://long1tail-quicknotes.hf.space/health
  done
0.312
0.298
0.301
0.289
0.295
```

### Cold latency:
| Attempt | Start time |
------------------------
| 1 | 18.4 s
| 2 | 16.1 s
| 3 | 17.8 s

- d. Cloud run is optimised on fast start, it keeps keeps image in cache. HF just stops container in VM and next start requires this container to boot again.
- e. HF's default port is 7860. quicknotes' image ddesined to listen port 8080. Flag `app_port` redirects traffic
- f. By building on HF we violates Build Once, Deploy Anywhere principle. Also, it makes deploy faster.

### Bonus

```
docker compose up -d    # QuickNotes on localhost:8080
cloudflared tunnel --url http://localhost:8080 # assigned https://carb-spine-tier-winter.trycloudflare.com
```

![Verification](image.png)


| Metric | HF Spaces (hosted)  | Cloudflare Tunnel (local-via-edge) |
|--------|---------------------|------------------------------------|
| Warm p50 | 305 ms | 54 ms |
| Warm p95 | 400 ms | 89 ms |
| Cold start | ~19.5 s | N/A (continuously local)
| Public URL stability | stable | requires laptop running permanently |
| Cost | 5 hole from dohnut | 30 kg of last-year snow |

(just kidding, both variants are free)

- g. HF is true cloud, as all operations take place on some external server. cloud run just provides a tunnel and still requires resources of my machine. for a user there is no difference, he still gets a public URL.
- h. HF case: Mostly distance between server and client. Cloudflare: route from corner CF server to client and processing
- i. It's perfect for externall access to resources in closed, local networks. But not for public web apps, as it have limits in reliability and troughput.