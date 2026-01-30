# Lab 11 — Decentralized Web Hosting with IPFS & 4EVERLAND

## Task 1 — Local IPFS Node Setup and File Publishing

### 1. IPFS Node Peer Count

After starting the IPFS Docker container and opening the Web UI (`http://127.0.0.1:5001/webui/`), the node successfully connected to the IPFS network.

**Peer count observed:**  
**603 peers**

![Peers count](https://github.com/user-attachments/assets/ccd75f1e-b2c8-4f37-a96b-aabea34eeb74)

---

### 2. Network Bandwidth Statistics

The Web UI dashboard shows healthy incoming and outgoing traffic, indicating active participation in the IPFS swarm.

![Network bandwidth statistics](https://github.com/user-attachments/assets/d06d4755-b76f-47f0-bf40-c3a5a3fea701)

---

### 3. Test File CID

A test file was created and added to IPFS using:

```bash
echo "Hello IPFS Lab" > testfile.txt
docker cp testfile.txt ipfs_node:/export/
docker exec ipfs_node ipfs add /export/testfile.txt
```

**Generated CID:**

```
QmUFJmQRosK4Amzcjwbip8kV3gkJ8jqCURjCNxuv3bWYS1
```

---

### 4. Local Gateway Access

The file was successfully accessed through the local IPFS gateway:

```
http://localhost:8080/ipfs/QmUFJmQRosK4Amzcjwbip8kV3gkJ8jqCURjCNxuv3bWYS1
```

![local gateway ui](https://github.com/user-attachments/assets/dde87819-86aa-48f5-8ead-5eef31e5b7dd)

---

### 5. Public Gateway Access

The file is available through public IPFS gateways:

* [https://ipfs.io/ipfs/QmUFJmQRosK4Amzcjwbip8kV3gkJ8jqCURjCNxuv3bWYS1](https://ipfs.io/ipfs/QmUFJmQRosK4Amzcjwbip8kV3gkJ8jqCURjCNxuv3bWYS1)
* [https://cloudflare-ipfs.com/ipfs/QmUFJmQRosK4Amzcjwbip8kV3gkJ8jqCURjCNxuv3bWYS1](https://cloudflare-ipfs.com/ipfs/QmUFJmQRosK4Amzcjwbip8kV3gkJ8jqCURjCNxuv3bWYS1)

Both gateways successfully display the file content after a short propagation delay.

---

### 6. Analysis: IPFS Content Addressing vs Traditional URLs

Traditional (Web 2.0) URLs use **location-based addressing** — they point to *where* the content is hosted (domain, server, path).
This creates issues such as:

* single point of failure
* dependency on hosting provider
* possibility of link rot
* content may change at the same URL

IPFS uses **content-based addressing**, where the CID is a cryptographic hash of the data. This means:

* the address depends on *what* the content is, not *where* it is stored
* content is verifiable — any modification changes the CID
* the content can be served by any IPFS node that stores it
* eliminates single points of failure

This provides stronger guarantees of integrity, immutability, and decentralization.

---

### 7. Reflection: Advantages and Disadvantages of Decentralized Storage

#### ✔ Advantages

* **High resilience:** Data is available as long as *one node* in the network has it.
* **Censorship resistance:** No central authority controls hosting.
* **Integrity:** Content cannot be tampered with without changing the CID.
* **Distributed performance:** Content can be fetched from the nearest peer.

#### ✘ Disadvantages

* **Propagation delays:** Public gateways may take several minutes to fetch new content.
* **Mutable updates are harder:** Any file change produces a new CID.
* **Availability depends on pinning:** Unpinned content can be garbage-collected.
* **Less user-friendly:** CIDs are long and not human-readable.

---

# Task 2 — Static Site Deployment with 4EVERLAND

### 1. 4EVERLAND Project URL

The deployed static website is available at:

```
https://f25-devops-intro-dzimbzxm-belyakova-anna.ipfs.4everland.app/
```

This URL points to the IPFS-hosted version of the site served through 4EVERLAND's infrastructure.

---

### 2. GitHub Repository Used

The GitHub repository connected to the 4EVERLAND deployment pipeline:

```
https://github.com/belyakova-anna/F25-DevOps-Intro
```

This repository contains the static site located in `labs/lab11/app`, which is automatically deployed whenever changes are pushed to the selected branch (`main`).

---

### 3. IPFS CID from 4EVERLAND Dashboard

During deployment, 4EVERLAND generated and pinned the following IPFS CID for the website:

```
bafybeifhpby7u3zpsa2ywhwh5ckn2gsdsniygytew6jxok3nvkiq5t3v3e
```

This CID uniquely identifies the deployed static site content.

---

### 4. Deployment Dashboard Screenshot

4EVERLAND deployment overview (status, CID, commit, duration):

![deployment dashboard](https://github.com/user-attachments/assets/d1f5db3b-ea17-481e-89c5-d3c931f094d1)

---

### 5. Site Accessed Through 4EVERLAND Domain

The site renders successfully using the `.4everland.app` gateway:

![site accessed through 4everland](https://github.com/user-attachments/assets/dfa7fa1a-e5bf-4cf6-9ddd-3fa7354884f0)

---

### 6. Site Accessed Through a Public IPFS Gateway

The same site was accessed directly using the public `ipfs.io` gateway and the deployment CID:

```
https://ipfs.io/ipfs/bafybeifhpby7u3zpsa2ywhwh5ckn2gsdsniygytew6jxok3nvkiq5t3v3e
```

![site accessed through ipfs](https://github.com/user-attachments/assets/eb744175-0731-4d1f-b588-ee1a2a69b2be)

---

### 7. Analysis: How 4EVERLAND Simplifies IPFS Deployment

Deploying directly to IPFS normally requires:

* running an IPFS node
* pinning content
* managing updates manually
* distributing CIDs and dealing with versioning

4EVERLAND automates all of this:

✔ integrates with GitHub for CI/CD

✔ automatically builds and publishes content to IPFS

✔ provides stable domain routing (`*.4everland.app`)

✔ handles pinning and persistence

✔ regenerates CID on each deployment

✔ abstracts away the IPFS API and gateway interactions

This makes decentralized hosting accessible even to beginners and removes operational overhead.

---

### 8. Comparison: Traditional Hosting vs IPFS Hosting

| Feature     | Traditional Web Hosting              | IPFS / 4EVERLAND Hosting          |
| ----------- | ------------------------------------ | --------------------------------- |
| Addressing  | Location-based URL (server-specific) | Content-addressed (CID)           |
| Reliability | Single point of failure              | Redundant, pulled from many peers |
| Mutability  | Easy to change content               | Changes create new CIDs           |
| Deployment  | Centralized server pushes            | Decentralized IPFS publishing     |
| Censorship  | Content can be restricted            | Highly censorship-resistant       |
| Performance | Depends on server location           | Can fetch from closest peer       |

**IPFS trade-offs:**

✔ strong integrity, decentralization, resilience

✘ slower propagation, versioning complexity, gateway inconsistencies
