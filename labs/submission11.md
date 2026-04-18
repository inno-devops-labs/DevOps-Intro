# Lab 11 - Decentralized Web Hosting with IPFS & 4EVERLAND

## Student Info
- Name: TODO
- Group: TODO
- Date: 2026-04-18
- Branch: feature/lab11

## Task 1 - Local IPFS Node Setup and File Publishing

### Commands Used

```powershell
docker run -d --name ipfs_node `
  -v ipfs_staging:/export `
  -v ipfs_data:/data/ipfs `
  -p 4001:4001 -p 8080:8080 -p 5001:5001 `
  ipfs/kubo:latest

Start-Sleep -Seconds 60

docker exec ipfs_node ipfs swarm peers
"Hello IPFS Lab" | Set-Content -Path testfile.txt
docker cp testfile.txt ipfs_node:/export/
docker exec ipfs_node ipfs add /export/testfile.txt
```

### Results
- IPFS node peer count: TODO
- Network bandwidth statistics: TODO
- Test file CID: TODO
- Local gateway URL: `http://localhost:8080/ipfs/TODO`
- Public gateway URL 1: `https://ipfs.io/ipfs/TODO`
- Public gateway URL 2: `https://cloudflare-ipfs.com/ipfs/TODO`

### Evidence
- Screenshot of IPFS Web UI: TODO
- Screenshot of local gateway access: TODO
- Screenshot of public gateway access: TODO

### Command Output Notes
- `docker exec ipfs_node ipfs swarm peers`: TODO
- `docker exec ipfs_node ipfs add /export/testfile.txt`: TODO

### Analysis: How IPFS Content Addressing Differs from Traditional URLs
Traditional URLs point to a location such as a domain name and path on a specific server. If that server is down, moved, or the file changes, the same URL may stop working or return different content. IPFS uses content addressing instead of location addressing. A CID is derived from the content itself, so the identifier changes when the content changes.

This means IPFS verifies integrity automatically. If someone retrieves content with a given CID, they know they received exactly the data that matches that hash. In the traditional web, trust usually depends on the server and transport layer. In IPFS, trust is tied more directly to the content fingerprint.

### Reflection: Advantages and Disadvantages of Decentralized Storage
Advantages:
- Better resilience because content can be served by multiple peers instead of one central server.
- Built-in integrity checking because content is addressed by hash.
- Easier long-term distribution of static content when files are pinned by multiple nodes or providers.

Disadvantages:
- Content may take time to propagate to public gateways.
- Availability depends on pinning; unpinned content can disappear.
- User experience is less familiar than traditional hosting, especially when custom domains, cache behavior, and updates are involved.

## Task 2 - Static Site Deployment with 4EVERLAND

### Project Configuration
- GitHub repository: `git@github.com:creatlan/DevOps-Intro.git`
- Branch deployed: `feature/lab11`
- Publish directory: `labs/lab11/app`
- 4EVERLAND project URL: TODO
- 4EVERLAND IPFS CID: TODO
- Public gateway URL: `https://ipfs.io/ipfs/TODO`

### Deployment Evidence
- Screenshot of 4EVERLAND dashboard: TODO
- Screenshot of site on `*.4everland.app`: TODO
- Screenshot of site on public IPFS gateway: TODO

### What I Deployed
The static site for this task is already located in `labs/lab11/app`. 4EVERLAND can deploy this directory directly without an additional build step if the project is configured as a static site.

### Analysis: How 4EVERLAND Simplifies IPFS Deployment
4EVERLAND makes IPFS hosting easier by handling the workflow that would otherwise require several manual steps. Instead of running local IPFS commands, pinning content manually, and managing a public endpoint yourself, 4EVERLAND connects to the Git repository and publishes the selected directory automatically.

It also provides a deployment dashboard, a stable `*.4everland.app` address, and repeatable redeployments when the repository changes. In practice, this feels similar to CI/CD for decentralized hosting: push code, let the platform publish it to IPFS, and then verify the resulting CID and public URL.

### Comparison: Traditional Web Hosting vs IPFS Hosting
| Topic | Traditional hosting | IPFS hosting |
| --- | --- | --- |
| Addressing | Location-based URL | Content-based CID |
| Availability | Depends on server uptime | Can be served by multiple peers if pinned |
| Updates | Replace files at same URL | New content produces a new CID |
| Integrity | Verified mainly through transport and server trust | Verified through content hash |
| Ease of use | Mature, simple, predictable | More complex, gateway and pinning behavior matter |

### Short Conclusion
Traditional hosting is still simpler for dynamic applications and predictable production operations. IPFS hosting is strong for immutable static content, resilience, and verifiable distribution. 4EVERLAND reduces much of the operational complexity, which makes decentralized deployment much more practical for normal developer workflows.

## Cleanup

```powershell
docker stop ipfs_node
docker rm ipfs_node
Remove-Item testfile.txt
```

## Git Commands for This Lab

```powershell
git fetch origin
git switch -c feature/lab11 origin/main

# fill labs/submission11.md after completing the tasks
git add labs/submission11.md
git commit -m "docs: add lab11 submission"
git push -u origin feature/lab11
```

## PR Checklist
- [ ] Task 1 - Local IPFS Node Setup and File Publishing
- [ ] Task 2 - Static Site Deployment with 4EVERLAND

## What Is Still Missing
- Fill in student name and group.
- Run the IPFS container and record peer count, bandwidth stats, and CID.
- Add screenshots for Task 1.
- Deploy `labs/lab11/app` to 4EVERLAND and record the site URL and CID.
- Add screenshots for Task 2.
- Push branch `feature/lab11` and open PR to the course repository `main`.
