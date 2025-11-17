# Lab 6 — Container Fundamentals with Docker

![difficulty](https://img.shields.io/badge/difficulty-intermediate-yellow)
![topic](https://img.shields.io/badge/topic-Containers-blue)
![points](https://img.shields.io/badge/points-10-orange)

> **Goal:** Master Docker fundamentals through hands-on container management, image operations, networking, and storage tasks.  
> **Deliverable:** A PR from `feature/lab6` to the course repo with `labs/submission6.md` containing all task outputs and analysis. Submit the PR link via Moodle.

---

## Overview

In this lab you will practice:
- Managing **container lifecycle** and understanding image-container relationships.
- Creating **custom Docker images** and analyzing filesystem changes.
- Implementing **Docker networking** for container communication.
- Using **volumes** for data persistence across container lifecycles.

These skills are essential for containerized application development and deployment in DevOps workflows.

---

## Tasks

### Task 1 — Container Lifecycle & Image Management (3 pts)

**Objective:** Master container lifecycle operations and understand the relationship between images and containers.

#### 1.1: Basic Container Operations

1. **List Existing Containers:**

   ```sh
   docker ps -a
   ```

2. **Pull Ubuntu Image:**

   ```sh
   docker pull ubuntu:latest
   docker images ubuntu
   ```

3. **Run Interactive Container:**
  
   ```sh
   docker run -it --name ubuntu_container ubuntu:latest
   ```

   Inside the container, explore:
   - Check OS version: `cat /etc/os-release`
   - List processes: `ps aux`
   - Exit with `exit`

#### 1.2: Image Export and Dependency Analysis

1. **Export the Image:**

   ```sh
   docker save -o ubuntu_image.tar ubuntu:latest
   ls -lh ubuntu_image.tar
   ```

2. **Attempt Image Removal:**

   ```sh
   docker rmi ubuntu:latest
   ```

3. **Remove Container and Retry:**

   ```sh
   docker rm ubuntu_container
   docker rmi ubuntu:latest
   ```

In `labs/submission6.md`, document:
- Output of `docker ps -a` and `docker images`
- Image size and layer count
- Tar file size comparison with image size
- Error message from the first removal attempt
- Analysis: Why does image removal fail when a container exists? Explain the dependency relationship.
- Explanation: What is included in the exported tar file?

---

### Task 2 — Custom Image Creation & Analysis (3 pts)

**Objective:** Create custom images from running containers and understand filesystem changes.

#### 2.1: Deploy and Customize Nginx

1. **Deploy Nginx Container:**

   ```sh
   docker run -d -p 80:80 --name nginx_container nginx
   curl http://localhost
   ```

2. **Create Custom HTML:**

   Create a file named `index.html` with the following content:

   ```html
   <html>
   <head>
   <title>The best</title>
   </head>
   <body>
   <h1>website</h1>
   </body>
   </html>
   ```

3. **Copy Custom Content:**

   ```sh
   docker cp index.html nginx_container:/usr/share/nginx/html/
   curl http://localhost
   ```

#### 2.2: Create and Test Custom Image

1. **Commit Container to Image:**

   ```sh
   docker commit nginx_container my_website:latest
   docker images my_website
   ```

2. **Remove Original and Deploy from Custom Image:**

   ```sh
   docker rm -f nginx_container
   docker run -d -p 80:80 --name my_website_container my_website:latest
   curl http://localhost
   ```

3. **Analyze Filesystem Changes:**

   ```sh
   docker diff my_website_container
   ```

   <details>
   <summary>🔍 Understanding docker diff output</summary>

   - `A` = Added file or directory
   - `C` = Changed file or directory
   - `D` = Deleted file or directory

   </details>

In `labs/submission6.md`, document:
- Screenshot or output of original Nginx welcome page
- Custom HTML content and verification via curl
- Output of `docker diff my_website_container`
- Analysis: Explain the diff output (A=Added, C=Changed, D=Deleted)
- Reflection: What are the advantages and disadvantages of `docker commit` vs Dockerfile for image creation?

---

### Task 3 — Container Networking & Service Discovery (2 pts)

**Objective:** Explore Docker's built-in networking and DNS-based service discovery.

#### 3.1: Create Custom Network

1. **Create Bridge Network:**

   ```sh
   docker network create lab_network
   docker network ls
   ```

2. **Deploy Connected Containers:**

   ```sh
   docker run -dit --network lab_network --name container1 alpine ash
   docker run -dit --network lab_network --name container2 alpine ash
   ```

#### 3.2: Test Connectivity and DNS

1. **Test Container-to-Container Communication:**

   ```sh
   docker exec container1 ping -c 3 container2
   ```

2. **Inspect Network Details:**

   ```sh
   docker network inspect lab_network
   ```

3. **Check DNS Resolution:**

   ```sh
   docker exec container1 nslookup container2
   ```

In `labs/submission6.md`, document:
- Output of ping command showing successful connectivity
- Network inspection output showing both containers' IP addresses
- DNS resolution output
- Analysis: How does Docker's internal DNS enable container-to-container communication by name?
- Comparison: What advantages does user-defined bridge networks provide over the default bridge network?

---

### Task 4 — Data Persistence with Volumes (2 pts)

**Objective:** Understand data persistence across container lifecycles using Docker volumes.

#### 4.1: Create and Use Volume

1. **Create Named Volume:**

   ```sh
   docker volume create app_data
   docker volume ls
   ```

2. **Deploy Container with Volume:**

   ```sh
   docker run -d -p 80:80 -v app_data:/usr/share/nginx/html --name web nginx
   ```

3. **Add Custom Content:**

   Create a custom `index.html` file:

   ```html
   <html><body><h1>Persistent Data</h1></body></html>
   ```

   Copy to volume:

   ```sh
   docker cp index.html web:/usr/share/nginx/html/
   curl http://localhost
   ```

#### 4.2: Verify Persistence

1. **Destroy and Recreate Container:**

   ```sh
   docker stop web && docker rm web
   docker run -d -p 80:80 -v app_data:/usr/share/nginx/html --name web_new nginx
   curl http://localhost
   ```

2. **Inspect Volume:**

   ```sh
   docker volume inspect app_data
   ```

In `labs/submission6.md`, document:
- Custom HTML content used
- Output of curl showing content persists after container recreation
- Volume inspection output showing mount point
- Analysis: Why is data persistence important in containerized applications?
- Comparison: Explain the differences between volumes, bind mounts, and container storage. When would you use each?

---

## How to Submit

1. Create a branch for this lab and work on your tasks:

   ```bash
   git switch -c feature/lab6
   # Complete all tasks and document in labs/submission6.md
   git add labs/submission6.md
   git commit -m "docs: add lab6 submission"
   git push -u origin feature/lab6
   ```

2. Open a PR from your fork's `feature/lab6` branch → **course repository's main branch**.

3. In the PR description, include:

   ```text
   - [x] Task 1 — Container Lifecycle & Image Management
   - [x] Task 2 — Custom Image Creation & Analysis
   - [x] Task 3 — Container Networking & Service Discovery
   - [x] Task 4 — Data Persistence with Volumes
   ```

4. **Copy the PR URL** and submit it via **Moodle before the deadline**.

---

## Acceptance Criteria

- ✅ Branch `feature/lab6` exists with commits for each task.
- ✅ File `labs/submission6.md` contains required outputs and analysis for Tasks 1-4.
- ✅ All Docker commands executed successfully with documented outputs.
- ✅ Analysis sections demonstrate understanding of Docker concepts.
- ✅ PR from `feature/lab6` → **course repo main branch** is open.
- ✅ PR link submitted via Moodle before the deadline.

---

## Rubric (10 pts)

| Criterion                                            | Points |
| ---------------------------------------------------- | -----: |
| Task 1 — Container Lifecycle & Image Management      |  **3** |
| Task 2 — Custom Image Creation & Analysis            |  **3** |
| Task 3 — Container Networking & Service Discovery    |  **2** |
| Task 4 — Data Persistence with Volumes               |  **2** |
| **Total**                                            | **10** |

---

## Guidelines

- Use clear Markdown headers to organize sections in `submission6.md`.
- Include both command outputs and written analysis for each task.
- Take screenshots where helpful for demonstrating successful execution.
- Focus on understanding Docker's architecture rather than just executing commands.
- Provide thoughtful analysis demonstrating conceptual understanding.

<details>
<summary>📚 Helpful Resources</summary>

- [Docker Documentation](https://docs.docker.com/)
- [Docker CLI Reference](https://docs.docker.com/engine/reference/commandline/cli/)
- [Docker Networking Overview](https://docs.docker.com/network/)
- [Docker Storage Overview](https://docs.docker.com/storage/)

</details>

<details>
<summary>💡 Docker Best Practices</summary>

1. Always clean up stopped containers and unused images to conserve disk space.
2. Use meaningful names for containers and images for easier management.
3. Understand the difference between ephemeral container storage and persistent volumes.
4. Use `docker logs` for debugging before attempting to enter containers.

</details>

<details>
<summary>🔒 Security Notes</summary>

1. Never expose containers on port 80 in production without proper security measures.
2. Use specific image tags instead of `latest` in production environments.
3. Regularly update base images to include security patches.
4. Be cautious with `docker commit` - Dockerfiles provide better traceability and reproducibility.

</details>