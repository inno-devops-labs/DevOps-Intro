# Lab 11 - Decentralized Web Hosting with IPFS & 4EVERLAND

## Task 1 - Local IPFS Node Setup and File Publishing

### 1.1 Start IPFS Container

```bash
docker run -d --name ipfs_node \
  -v ipfs_staging:/export \
  -v ipfs_data:/data/ipfs \
  -p 4001:4001 -p 8080:8080 -p 5001:5001 \
  ipfs/kubo:latest
```

### 1.2 Verify Node Operation

- IPFS node status: running (healthy)
- Peer count (`ipfs swarm peers | wc -l`): **33**
- Bandwidth stats (`ipfs stats bw`):
  - TotalIn: **677 kB**
  - TotalOut: **52 kB**
  - RateIn: **271 kB/s**
  - RateOut: **17 kB/s**

### 1.3 Add File to IPFS

```bash
echo "Hello IPFS Lab from VM" > testfile.txt
docker cp testfile.txt ipfs_node:/export/testfile.txt
docker exec ipfs_node ipfs add /export/testfile.txt
```

Generated CID:
- Test file CID: **QmSKCNXeBXrVv2pmiLAyW6ECE8SYs9GLthp5kdk7T5WoUT**

Also published lab static app folder (`labs/lab11/app`) to IPFS:
- App CID: **QmYLMRV9N7dXBeLfMs9qDAkEN52AGoCnNA1r4xvWGgv4tZ**

### 1.4 Access Content

- Local gateway:
  - `http://localhost:8080/ipfs/QmSKCNXeBXrVv2pmiLAyW6ECE8SYs9GLthp5kdk7T5WoUT`
  - Browser evidence also uses local subdomain-style gateway: `http://bafybeib3b5rq5doym337qofmpgyud3riqk6vkpcuf2zybas64kx5lasxa.ipfs.localhost:8080`
- Public gateways:
  - `https://ipfs.io/ipfs/QmSKCNXeBXrVv2pmiLAyW6ECE8SYs9GLthp5kdk7T5WoUT` (HTTP 200)
  - `https://cloudflare-ipfs.com/ipfs/QmSKCNXeBXrVv2pmiLAyW6ECE8SYs9GLthp5kdk7T5WoUT` (not reachable in this run)
  - `https://dweb.link/ipfs/QmSKCNXeBXrVv2pmiLAyW6ECE8SYs9GLthp5kdk7T5WoUT` (HTTP 200)

Local gateway content check returned expected text:
- `Hello IPFS Lab from VM at 2026-05-12T18:25:43+03:00`

### Task 1 Artifacts

- `labs/artifacts/lab11/ipfs-container-id.txt`
- `labs/artifacts/lab11/ipfs-ready.txt`
- `labs/artifacts/lab11/ipfs-id.txt`
- `labs/artifacts/lab11/ipfs-swarm-peers.txt`
- `labs/artifacts/lab11/ipfs-peer-count.txt`
- `labs/artifacts/lab11/ipfs-bw.txt`
- `labs/artifacts/lab11/ipfs-add-testfile.txt`
- `labs/artifacts/lab11/testfile.cid`
- `labs/artifacts/lab11/local-gateway-testfile.txt`
- `labs/artifacts/lab11/ipfsio-status.txt`
- `labs/artifacts/lab11/cloudflare-status.txt`
- `labs/artifacts/lab11/dweb-status.txt`
- `labs/artifacts/lab11/lab11-app.cid`
- `labs/artifacts/lab11/summary.env`

### Analysis - Content Addressing vs Traditional URLs

Traditional web URLs point to a location (`protocol + host + path`). If server location changes or server is down, content becomes unavailable.

IPFS uses content addressing: CID is derived from content hash. Address points to "what the content is", not "where it is hosted". If any peer pins that CID, content can still be fetched through gateways or P2P routing.

### Reflection - Advantages and Disadvantages of Decentralized Storage

Advantages:
- Better resilience (no single hosting point)
- Integrity by hash (content tampering changes CID)
- Natural deduplication and distribution

Disadvantages:
- Availability depends on pinning and gateway reachability
- Public gateway propagation latency may appear
- Operational model differs from classic CDN/server hosting

---

## Task 2 - Static Site Deployment with 4EVERLAND

### 2.1 Project Setup

Repository used for deploy source:
- `https://github.com/krasand/DevOps-Intro`

Publish directory planned for deployment:
- `labs/lab11/app`

### 2.2 Deployment Verification

Deployment values from 4EVERLAND dashboard:
- Primary 4EVERLAND project URL: **https://devops-intro-lkhhyryu-krasand.ipfs.4everland.app/**
- Additional assigned domain: **https://devops-intro-6-6vv8.ipfs.4everland.app/**
- Deployment CID (Site Info): **bafybeifhpby7u3zpsa2ywhwh5ckn2gsdsniygytew6jxok3nvkiq5t3v3e**
- Public CID URL used for verification: **https://bafybeifhpby7u3zpsa2ywhwh5ckn2gsdsniygytew6jxok3nvkiq5t3v3e.ipfs.inbrowser.link**

Screenshots attached as evidence:
- Screenshot 1: site opened by CID URL (`...ipfs.inbrowser.link`)
- Screenshot 2: site opened by `*.4everland.app` domain
- Screenshot 3: 4EVERLAND deployment dashboard with status/CID
- Screenshot 4: local gateway (`localhost:8080`) output of IPFS test file
- Screenshot 5: IPFS Web UI (`127.0.0.1:5001`) with node status/peers

### Analysis - 4EVERLAND vs Manual IPFS Deployment

4EVERLAND simplifies decentralized hosting by providing a CI/CD-style flow: connect repo, set publish directory, and get automatic pinning/deployments with a stable domain front.

Manual IPFS deployment gives lower-level control and transparency, but requires running node lifecycle, pinning strategy, and custom gateway/domain handling yourself.

### Comparison - Traditional Hosting vs IPFS Hosting

Traditional hosting:
- Easy operational model and mature tooling
- Centralized and provider-dependent

IPFS hosting:
- Content integrity and decentralization benefits
- Requires pinning/gateway strategy and has ecosystem-specific trade-offs

---

## Conclusion

Task 1 was fully completed on the VM with real IPFS node execution, CID generation, and gateway validation.

Task 2 was completed via 4EVERLAND with successful deployment and verified access by both 4EVERLAND domain and CID-based public gateway.
