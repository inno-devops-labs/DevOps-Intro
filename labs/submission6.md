# Lab 6 — Container Fundamentals with Docker

## Task 1 — Container Lifecycle & Image Management

## Task 1 — Container Lifecycle & Image Management

### Output of `docker ps -a`

The command below shows all containers in the system, including stopped ones.

```bash
docker ps -a
```

CONTAINER ID   IMAGE                COMMAND                  CREATED        STATUS                        PORTS                                NAMES
772ceeda23cf   scylladb/scylla      "/docker-entrypoint.…"   5 days ago     Exited (255) 22 seconds ago   22/tcp, 7000-7001/tcp, 9160/tcp, 9180/tcp, 10000/tcp, 0.0.0.0:9042->9042/tcp   scylla
823c1f1e4011   rl_project-dashboard "streamlit run unifi…"   3 months ago   Exited (0) 3 months ago                                            ecommerce_dashboard
f03d3945dce7   rl_project-api       "python api_server.py"   3 months ago   Exited (137) 3 months ago                                          ecommerce_api


This command lists locally stored Docker images.
``` bash
docker images ubuntu
```

Output:

REPOSITORY   TAG       IMAGE ID       CREATED       SIZE
ubuntu       latest    bbdabce66f1b   4 weeks ago   78.1MB

### Image Size and Layers

The Ubuntu image size is 78.1 MB.
Docker images are composed of multiple read-only filesystem layers that together form the container filesystem.

### Tar File Size Comparison

The image was exported using:

```bash
docker save -o ubuntu_image.tar ubuntu:latest
```

The tar archive contains the same image layers and metadata, so its size is similar to the Docker image size.

### Error During Image Removal

Attempting to remove the image produced the following error:

Error response from daemon: conflict: unable to remove repository reference "ubuntu:latest"
container is using its referenced image
### Analysis — Why Image Removal Fails

Image removal fails because a container was created from this image.
Docker prevents deleting images that are still used by containers to avoid breaking container dependencies.

## Task 2

### Original Nginx Welcome Page

First, the Nginx container was started:
```bash
docker run -d -p 80:80 --name nginx_container nginx
```

Then I checked the page using curl:
```bash
curl http://localhost
```
Output showed the default Nginx page:

<title>Welcome to nginx!</title>

Status code:

StatusCode : 200
StatusDescription : OK

This confirms that the Nginx container started correctly and serves the default page.

### Custom HTML Content

I replaced the default page with my own HTML file:

docker cp index.html nginx_container:/usr/share/nginx/html/

Then I verified the result:

curl http://localhost

Output:

<html>
<head>
<title>The best</title>
</head>
<body>
<h1>website</h1>
</body>
</html>

This confirms that the custom website was successfully deployed inside the container.

### Creating Custom Docker Image

Next, I saved the modified container as a new image:

docker commit nginx_container my_website:latest

Check image:

docker images my_website

Output:

REPOSITORY   TAG       IMAGE ID       SIZE
my_website   latest    6f97c1c0ab1c   161MB
### Running Container From Custom Image

The old container was removed:

docker rm -f nginx_container

Then a new container was created from the custom image:

docker run -d -p 80:80 --name my_website_container my_website:latest

Verification:

curl http://localhost

Output again shows the custom page:

<h1>website</h1>

This confirms the new image contains the modified website.

### Docker Diff Output

Command:

docker diff my_website_container

Output:

C /etc
C /etc/nginx
C /etc/nginx/conf.d
C /etc/nginx/conf.d/default.conf
C /run
C /run/nginx.pid
Diff Explanation

Docker diff shows filesystem changes inside the container.

Symbols meaning:

A (Added) — new files were created

C (Changed) — existing files were modified

D (Deleted) — files were removed

In this case, the output mostly shows C (Changed) entries, meaning configuration files and runtime files were modified during container execution.

### Reflection: docker commit vs Dockerfile

docker commit

Advantages:

Very fast way to create an image

Useful for quick experiments

No need to write configuration files

Disadvantages:

Not reproducible

Harder to track changes

Not recommended for production

Dockerfile

Advantages:

Reproducible builds

Version controlled

Clear documentation of steps

Disadvantages:

Slightly slower to set up

Requires writing configuration

In practice, Dockerfiles are preferred for production environments.

## Task 3 — Container Networking & Service Discovery

### Creating a Custom Network

First, I created a user-defined bridge network:

docker network create lab_network

Then I verified it:

docker network ls

Output shows the new network:

lab_network    bridge    local

### Running Containers in the Network

Two Alpine containers were started inside the network:

docker run -dit --network lab_network --name container1 alpine ash
docker run -dit --network lab_network --name container2 alpine ash

### Connectivity Test (Ping)

I tested connectivity between containers:

docker exec container1 ping -c 3 container2

Output:

PING container2 (172.21.0.3): 56 data bytes
64 bytes from 172.21.0.3: seq=0 ttl=64 time=0.767 ms
64 bytes from 172.21.0.3: seq=1 ttl=64 time=0.100 ms
64 bytes from 172.21.0.3: seq=2 ttl=64 time=0.121 ms

3 packets transmitted, 3 packets received, 0% packet loss

This confirms that the containers can communicate with each other.

### Network Inspection

Command:

docker network inspect lab_network

Important part of the output:

container1 -> 172.21.0.2
container2 -> 172.21.0.3
Subnet -> 172.21.0.0/16
Gateway -> 172.21.0.1

This shows both containers connected to the same network with different IP addresses.

### DNS Resolution

I checked DNS resolution inside the container:

docker exec container1 nslookup container2

Output:

Server: 127.0.0.11
Name: container2
Address: 172.21.0.3

This confirms that Docker resolves container names to their IP addresses.

### Analysis — Docker Internal DNS

Docker provides an internal DNS server inside user-defined networks.
When a container starts, Docker registers its name and IP address in the internal DNS.

Because of this, containers can communicate using container names instead of IP addresses.

For example:

container1 -> ping container2

Docker DNS automatically resolves:

container2 → 172.21.0.3

This makes container communication easier and avoids hardcoding IP addresses.

### Comparison — User-defined Bridge vs Default Bridge

User-defined bridge network advantages:

Automatic DNS resolution between containers

Containers can communicate using names

Better network isolation

Easier service discovery

More flexible configuration

Default bridge network limitations:

No automatic DNS name resolution

Containers must communicate using IP addresses

Less isolation and configuration options

Because of this, user-defined bridge networks are recommended for multi-container applications.


## Task 4 — Data Persistence with Volumes

### Creating a Docker Volume

First, I created a volume to store persistent data:

docker volume create app_data

Then I verified the volume:

docker volume ls

Output:

DRIVER    VOLUME NAME
local     app_data

### Running Nginx Container with Volume

I started an Nginx container and mounted the volume:

docker run -d -p 80:80 -v app_data:/usr/share/nginx/html --name web nginx

This command mounts the volume app_data to the Nginx web directory.

### Custom HTML Content

I copied a custom HTML file into the container:

docker cp index.html web:/usr/share/nginx/html/

Example HTML content:

<html>
<body>
<h1>Persistent Data</h1>
</body>
</html>

### Verifying Website Content

I checked the page using curl:

curl http://localhost

Output:

<html><body><h1>Persistent Data</h1></body></html>

Status:

StatusCode : 200
StatusDescription : OK

This confirms that the container is serving the custom content.

### Persistence After Container Recreation

Even after container recreation, the data remained available because it is stored in the volume.

Running curl again:

curl http://localhost

Output:

<html><body><h1>Persistent Data</h1></body></html>

This confirms that the data persisted independently of the container lifecycle.

### Volume Inspection

Command:

docker volume inspect app_data

Output:

Name: app_data
Driver: local
Mountpoint: /var/lib/docker/volumes/app_data/_data
Scope: local

This shows the location where Docker stores the volume data on the host system.

### Analysis — Why Data Persistence Is Important

Containers are designed to be ephemeral, meaning they can be created and destroyed quickly.
If data is stored only inside the container filesystem, it will be lost when the container is removed.

Using volumes ensures that important data remains available even if containers are recreated or updated.

This is essential for applications such as:

databases

web applications

logs

uploaded user files

### Comparison — Volumes vs Bind Mounts vs Container Storage
Container Storage

Data stored directly inside the container filesystem.

Pros

simple to use

Cons

data is lost when the container is removed

not suitable for persistent data

### Docker Volumes

Managed by Docker and stored in Docker's internal storage directory.

Pros

recommended for persistent data

better performance

portable between containers

managed by Docker

Cons

less direct access from host filesystem

### Bind Mounts

Maps a specific host directory to a container directory.

Example:

-v /host/path:/container/path

Pros

direct access from the host

useful for development

Cons

depends on host filesystem structure

less portable

potential security risks

