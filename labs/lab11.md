# Lab 11 — Decentralized Web Hosting with IPFS & 4EVERLAND

![difficulty](https://img.shields.io/badge/difficulty-intermediate-yellow)
![topic](https://img.shields.io/badge/topic-Web3%20%26%20IPFS-blue)
![points](https://img.shields.io/badge/points-10-orange)

> **Goal:** Explore decentralized web technologies by setting up a local IPFS node and deploying a static site using 4EVERLAND's automation platform.  
> **Deliverable:** A PR from `feature/lab11` to the course repo with `labs/submission11.md` containing IPFS CIDs, deployment URLs, and analysis. Submit the PR link via Moodle.

---

## Overview

In this lab you will practice:
- Setting up and running a **personal IPFS node** using Docker.
- Publishing files to the **decentralized IPFS network** and understanding content addressing.
- Deploying a **static website** to IPFS using 4EVERLAND's automation platform.
- Verifying content accessibility through multiple IPFS gateways.

IPFS (InterPlanetary File System) enables decentralized, content-addressed storage that's resilient to single-point failures. These skills prepare you for Web3 development and decentralized application hosting.

---

## Tasks

### Task 1 — Local IPFS Node Setup and File Publishing (5 pts)

**Objective:** Run a personal IPFS node using Docker, publish files to the IPFS network, and verify decentralized access through public gateways.

**Why This Matters:** IPFS provides a foundation for decentralized web hosting, ensuring content remains accessible even if individual servers go offline. Understanding IPFS is crucial for Web3 development.

#### 1.1: Start IPFS Container

1. **Deploy IPFS Node:**

   ```bash
   docker run -d --name ipfs_node \
     -v ipfs_staging:/export \
     -v ipfs_data:/data/ipfs \
     -p 4001:4001 -p 8080:8080 -p 5001:5001 \
     ipfs/kubo:latest
   ```

   <details>
   <summary>🔍 Understanding IPFS ports</summary>

   - `4001`: P2P communication with other IPFS nodes
   - `8080`: HTTP gateway for accessing IPFS content
   - `5001`: API endpoint for IPFS commands and Web UI

   </details>

2. **Wait for Initialization:**

   Wait 60 seconds for the node to initialize and connect to peers.

#### 1.2: Verify Node Operation

1. **Check Connected Peers:**

   ```bash
   docker exec ipfs_node ipfs swarm peers
   ```

   You should see a list of connected IPFS peers.

2. **Access IPFS Web UI:**

   Open your browser and navigate to: `http://127.0.0.1:5001/webui/`

   Explore:
   - Connected peers count
   - Network bandwidth statistics
   - Node status

#### 1.3: Add File to IPFS

1. **Create Test File:**

   ```bash
   echo "Hello IPFS Lab" > testfile.txt
   docker cp testfile.txt ipfs_node:/export/
   ```

2. **Add File to IPFS:**

   ```bash
   docker exec ipfs_node ipfs add /export/testfile.txt
   ```

   Note the generated CID (Content Identifier), e.g., `QmXgZAUWd8yo4tvjBETqzUy3wLx5YRzuDwUQnBwRGrAmAo`

#### 1.4: Access Content

1. **Via Local Gateway:**

   Open in browser: `http://localhost:8080/ipfs/<YOUR_CID>`

2. **Via Public Gateways:**

   - `https://ipfs.io/ipfs/<YOUR_CID>`
   - `https://cloudflare-ipfs.com/ipfs/<YOUR_CID>`

   > **Note:** Public gateway access may take 2-5 minutes to propagate

In `labs/submission11.md`, document:
- IPFS node peer count from Web UI
- Network bandwidth statistics
- Test file CID
- Screenshots of local gateway access
- Public gateway URLs
- Analysis: How does IPFS's content addressing differ from traditional URLs?
- Reflection: What are the advantages and disadvantages of decentralized storage?

---

### Task 2 — Static Site Deployment with 4EVERLAND (5 pts)

**Objective:** Deploy a website to IPFS using 4EVERLAND's automation platform and manage continuous deployment workflows.

**Why This Matters:** 4EVERLAND simplifies deploying and managing websites on decentralized infrastructure, providing CI/CD-like workflows for Web3 hosting with automatic IPFS publishing.

#### 2.1: Set Up 4EVERLAND Project

1. **Create Account:**

   Sign up at [4EVERLAND.org](https://www.4everland.org/) (use GitHub or wallet authentication)

2. **Create New Project:**

   <details>
   <summary>📋 Project Setup Steps</summary>

   1. Click "Create New Project" → "Connect GitHub repository"
   2. Select your current course repository (or any personal web app/site)
   3. Choose branch to deploy
   4. Configure build settings:
      - **Platform:** IPFS/Filecoin
      - **Framework:** Other (or select appropriate framework)
      - **Publish directory:** `labs/lab11/app` (adjust based on your project structure)
   5. Click "Deploy"

   </details>

#### 2.2: Verify Deployment

1. **Check Deployment Status:**

   In 4EVERLAND dashboard:
   - Wait for deployment to complete
   - Note the IPFS CID under "Site Info"
   - Access site via provided `*.4everland.app` subdomain

2. **Verify on Public Gateway:**

   Access your site via: `https://ipfs.io/ipfs/<CID-from-4EVERLAND>`

3. **Test Continuous Deployment (Optional):**

   - Make a change to your repository
   - Push to GitHub
   - Observe automatic redeployment in 4EVERLAND

In `labs/submission11.md`, document:
- 4EVERLAND project URL (`your-site.4everland.app`)
- GitHub repository used (if personal project)
- IPFS CID from 4EVERLAND dashboard
- Screenshots of:
  - 4EVERLAND deployment dashboard
  - Site accessed through 4EVERLAND domain
  - Site accessed through public IPFS gateway
- Analysis: How does 4EVERLAND simplify IPFS deployment compared to manual methods?
- Comparison: What are the trade-offs between traditional web hosting and IPFS hosting?

---

## How to Submit

1. Create a branch for this lab and push it to your fork:

   ```bash
   git switch -c feature/lab11
   # create labs/submission11.md with your findings
   git add labs/submission11.md
   git commit -m "docs: add lab11 submission"
   git push -u origin feature/lab11
   ```

2. Open a PR from your fork's `feature/lab11` branch → **course repository's main branch**.

3. In the PR description, include:

   ```text
   - [x] Task 1 — Local IPFS Node Setup and File Publishing
   - [x] Task 2 — Static Site Deployment with 4EVERLAND
   ```

4. **Copy the PR URL** and submit it via **Moodle before the deadline**.

---

## Acceptance Criteria

- ✅ Branch `feature/lab11` exists with commits for each task.
- ✅ File `labs/submission11.md` contains required outputs and analysis for Tasks 1-2.
- ✅ IPFS node successfully deployed with documented peer connections.
- ✅ Test file published to IPFS with valid CID.
- ✅ 4EVERLAND deployment completed with working site URL.
- ✅ Screenshots included as evidence.
- ✅ PR from `feature/lab11` → **course repo main branch** is open.
- ✅ PR link submitted via Moodle before the deadline.

---

## Rubric (10 pts)

| Criterion                                           | Points |
| --------------------------------------------------- | -----: |
| Task 1 — Local IPFS Node Setup and File Publishing  |  **5** |
| Task 2 — Static Site Deployment with 4EVERLAND      |  **5** |
| **Total**                                           | **10** |

---

## Guidelines

- Use clear Markdown headers to organize sections in `submission11.md`.
- Include both command outputs and written analysis for each task.
- Take clear screenshots showing successful deployments.
- Provide thoughtful analysis of decentralized web technologies.
- Document any challenges encountered during setup.

<details>
<summary>📚 Helpful Resources</summary>

- [IPFS Documentation](https://docs.ipfs.tech/)
- [IPFS Kubo (Go-IPFS) GitHub](https://github.com/ipfs/kubo)
- [4EVERLAND Documentation](https://docs.4everland.org/)
- [Understanding IPFS](https://docs.ipfs.tech/concepts/)
- [Content Addressing Explained](https://docs.ipfs.tech/concepts/content-addressing/)

</details>

<details>
<summary>💡 IPFS Tips</summary>

1. **Content Addressing:** IPFS uses CIDs (Content Identifiers) based on file content, not location.
2. **Propagation Delays:** Public gateway access may take time as content propagates through the network.
3. **Pinning:** Files need to be "pinned" to remain available; unpinned content may be garbage collected.
4. **Gateway Selection:** Different gateways may have different performance characteristics.
5. **Persistence:** 4EVERLAND pins your content automatically, ensuring availability.

</details>

<details>
<summary>🌐 Decentralized Web Concepts</summary>

**Traditional Web (Web 2.0):**
- Centralized servers
- Location-based addressing (URLs)
- Single point of failure
- Controlled by hosting providers

**Decentralized Web (Web3/IPFS):**
- Distributed peer-to-peer network
- Content-based addressing (CIDs)
- Resilient to server failures
- Censorship-resistant
- Content permanence through pinning

**Key Differences:**
- IPFS content is addressed by what it is (hash), not where it is (URL)
- Content remains accessible as long as at least one node has it
- No central authority controls content availability

</details>

<details>
<summary>🔧 Troubleshooting</summary>

**If IPFS node won't start:**
- Check Docker is running: `docker ps`
- Check port availability: `lsof -i :4001,8080,5001`
- View logs: `docker logs ipfs_node`

**If public gateways don't work:**
- Wait 2-5 minutes for network propagation
- Try different public gateways
- Verify CID is correct
- Check your local gateway works first

**If 4EVERLAND deployment fails:**
- Verify GitHub repository permissions
- Check build settings match your project structure
- Review deployment logs in 4EVERLAND dashboard

</details>