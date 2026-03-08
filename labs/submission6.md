## Task 1 — Container Lifecycle & Image Management

### Docker run ubuntu and inspect system

```text
root@67c83c117c15:/# cat /etc/os-release

PRETTY_NAME="Ubuntu 24.04.4 LTS"
NAME="Ubuntu"
VERSION_ID="24.04"
VERSION="24.04.4 LTS (Noble Numbat)"
VERSION_CODENAME=noble
ID=ubuntu
ID_LIKE=debian
HOME_URL="https://www.ubuntu.com/"
SUPPORT_URL="https://help.ubuntu.com/"
BUG_REPORT_URL="https://bugs.launchpad.net/ubuntu/"
UBUNTU_CODENAME=noble
LOGO=ubuntu-logo
```

### Running processes inside container

```bash
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root         1  0.0  0.0   4300  3636 pts/0    Ss   19:45   0:00 /bin/bash
root        10  0.0  0.0   7632  3656 pts/0    R+   19:45   0:00 ps aux
```

### Exported image size

```bash
-rw-------  1 leryamerlen  staff    29M Mar  8 22:46 ubuntu_image.tar
```

### Docker history ubuntu:latest

```bash
IMAGE          CREATED       CREATED BY                                      SIZE      COMMENT
d1e2e92c075e   3 weeks ago   /bin/sh -c #(nop)  CMD ["/bin/bash"]            0B        
<missing>      3 weeks ago   /bin/sh -c #(nop) ADD file:25d708bf0b30ddee2…   110MB     
<missing>      3 weeks ago   /bin/sh -c #(nop)  LABEL org.opencontainers.…   0B        
<missing>      3 weeks ago   /bin/sh -c #(nop)  LABEL org.opencontainers.…   0B        
<missing>      3 weeks ago   /bin/sh -c #(nop)  ARG LAUNCHPAD_BUILD_ARCH     0B        
<missing>      3 weeks ago   /bin/sh -c #(nop)  ARG RELEASE                  0B        
```

### First attempt to remove image

```bash
Error response from daemon: conflict: unable to delete ubuntu:latest (must be forced) - container 67c83c117c15 is using its referenced image d1e2e92c075e
```

### Removing container and image

```bash
docker rm ubuntu_container
ubuntu_container

docker rmi ubuntu:latest
Untagged: ubuntu:latest
Deleted: sha256:d1e2e92c075e5ca139d51a140fff46f84315c0fdce203eab2807c7e495eff4f9
```

### docker ps -a

```text
CONTAINER ID   IMAGE               COMMAND                  CREATED          STATUS                      PORTS                                 NAMES
517a9c3ddb8d   my_website:latest   "/docker-entrypoint.…"   19 minutes ago   Up 19 minutes               0.0.0.0:80->80/tcp, [::]:80->80/tcp   my_website_container
3846161d8a86   hello-world         "/hello"                 58 minutes ago   Exited (0) 58 minutes ago                                         blissful_diffie
```
### docker images ubuntu

```text
IMAGE           ID             DISK USAGE   CONTENT SIZE   EXTRA
ubuntu:latest   d1e2e92c075e        141MB         30.8MB
```

### Image size and layer count
According to docker images, the Ubuntu image has a disk usage of about 141 MB and a content size of 30.8 MB.

Based on the earlier docker history ubuntu:latest output, the image contains 6 history entries (layers or metadata build steps).

### Tar file size comparison

The exported image archive ubuntu_image.tar had a size of 29 MB, which is smaller than the disk usage reported by Docker.

This difference occurs because the tar archive stores the image layers and metadata in a compressed export format, while Docker may report the expanded layer sizes and additional metadata used internally by the container runtime

### Analysis

The first image removal failed because the container still depended on that image as its base filesystem. Docker does not remove images that are referenced by existing containers.

The exported tar file contains the image layers and metadata needed to load the image again later.


## Task 2 — Custom Image Creation & Analysis

![alt text](w_nginx.png)

### Deploy and customize Nginx container

First, I started an Nginx container and checked that the default page was available from the browser through localhost.

```bash
docker run -d -p 80:80 --name nginx_container nginx
curl http://localhost
```

### Original Nginx page

```html
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```

Then I created my own `index.html` file and copied it into the container to replace the default page.

```bash
docker cp index.html nginx_container:/usr/share/nginx/html/index.html
curl http://localhost
```

### Custom page output

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

### Create custom image from modified container

After that, I saved the modified container as a new Docker image called `my_website:latest`

```bash
docker commit nginx_container my_website:latest
docker images my_website
```

### Image information

```bash
IMAGE               ID             DISK USAGE   CONTENT SIZE   EXTRA
my_website:latest   02672b1f155c        255MB         61.3MB
```

### Run container from custom image

Then I removed the old container and started a new one from my custom image.

```bash
docker rm -f nginx_container
docker run -d -p 80:80 --name my_website_container my_website:latest
curl http://localhost
```

### Verification of custom image

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

This shows that the modified web page was successfully saved inside the new image

### Inspect filesystem changes

```bash
docker diff my_website_container
```

```text
C /etc
C /etc/nginx
C /etc/nginx/conf.d
C /etc/nginx/conf.d/default.conf
C /run
C /run/nginx.pid
```

### Analysis

In `docker diff`:
- `A` means a file or directory was added
- `C` means a file or directory was changed
- `D` means a file or directory was deleted

In my output, only `C` entries appeared, which means Docker detected changed files or directories compared to the original image. These changes are mainly related to Nginx runtime and configuration state after the container started.

`docker commit` is useful for quick experiments and fast image creation from a running container. However, it is not ideal for long-term use, because the steps are not explicit and the process is harder to reproduce.

A Dockerfile is better for reproducibility, version control, documentation, and maintenance, because every build step is written clearly and can be rebuilt at any time.

## Task 3 — Container Networking & Service Discovery

### Create custom Docker network

First, I created a user-defined bridge network and checked that it appeared in the Docker network list.

```bash
docker network create lab_network
docker network ls
```

### docker network ls output

```text
NAME          DRIVER    SCOPE
bridge        bridge    local
host          host      local
lab_network   bridge    local
none          null      local
```

### Run two containers in the same network

I started two Ubuntu containers and attached both of them to the `lab_network` network.

```bash
docker run -dit --network lab_network --name container1 ubuntu:latest bash
docker run -dit --network lab_network --name container2 ubuntu:latest bash
```

### Network inspection

Then I inspected the network configuration.

```bash
docker network inspect lab_network
```

```json
{
  "Name": "lab_network",
  "Driver": "bridge",
  "IPAM": {
    "Config": [
      {
        "Subnet": "172.18.0.0/16",
        "Gateway": "172.18.0.1"
      }
    ]
  },
  "Containers": {
    "container1": {
      "Name": "container1",
      "IPv4Address": "172.18.0.2/16"
    },
    "container2": {
      "Name": "container2",
      "IPv4Address": "172.18.0.3/16"
    }
  }
}
```

### Install networking tools in container1

The minimal Ubuntu image did not include `ping` and `nslookup`, so I installed the required packages inside `container1`.

```bash
docker exec container1 apt-get update
docker exec container1 apt-get install -y iputils-ping dnsutils
```

### Test connectivity with ping

```bash
docker exec container1 ping -c 3 container2
```

### Ping output

```text
PING container2 (172.18.0.3) 56(84) bytes of data.
64 bytes from container2.lab_network (172.18.0.3): icmp_seq=1 ttl=64 time=0.032 ms
64 bytes from container2.lab_network (172.18.0.3): icmp_seq=2 ttl=64 time=0.130 ms
64 bytes from container2.lab_network (172.18.0.3): icmp_seq=3 ttl=64 time=0.082 ms

--- container2 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2053ms
rtt min/avg/max/mdev = 0.032/0.081/0.130/0.040 ms
```

### Test DNS resolution

```bash
docker exec container1 nslookup container2
```

### DNS resolution output

```text
Server:		127.0.0.11
Address:	127.0.0.11#53

Non-authoritative answer:
Name:	container2
Address: 172.18.0.3
```

### Analysis

The network inspection shows that both containers were attached to the same user-defined bridge network and received IP addresses from the same subnet. `container1` received `172.18.0.2`, and `container2` received `172.18.0.3`.

The ping test confirmed that the containers could communicate directly over the Docker network.

The `nslookup` result shows that Docker provides internal DNS resolution for containers on the same user-defined network. Because of this, `container1` could resolve the name `container2` without manual IP configuration.

A user-defined bridge network is more convenient than the default bridge network because it supports automatic service discovery by container name, better isolation, and simpler communication between containers.


## Task 4 — Data Persistence with Volumes

### Create Docker volume

First, I created a Docker volume named `app_data` and verified that it appeared in the volume list.

```bash
docker volume create app_data
docker volume ls
```

### docker volume ls output

```text
DRIVER    VOLUME NAME
local     app_data
```

### Run Nginx container with mounted volume

Then I removed the previous container using port 80 and started a new Nginx container with the volume mounted to `/usr/share/nginx/html`.

```bash
docker rm -f my_website_container
docker run -d -p 80:80 -v app_data:/usr/share/nginx/html --name web nginx
curl http://localhost
```

### Initial page output

```html
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```

### Create custom HTML and copy it into the mounted volume

```bash
cat > index.html <<'EOF'
<html><body><h1>Persistent Data</h1></body></html>
EOF

docker cp index.html web:/usr/share/nginx/html/index.html
curl http://localhost
```

### Page output after update

```html
<html><body><h1>Persistent Data</h1></body></html>
```

### Remove and recreate container

After that, I stopped and removed the container, then created a new container using the same volume.

```bash
docker stop web && docker rm web
docker run -d -p 80:80 -v app_data:/usr/share/nginx/html --name web_new nginx
curl http://localhost
```

### Page output after container recreation

```html
<html><body><h1>Persistent Data</h1></body></html>
```

This shows that the custom page remained available after the original container was removed and a new one was created.

### Inspect volume

```bash
docker volume inspect app_data
```

### docker volume inspect output

```json
[
    {
        "CreatedAt": "2026-03-08T20:58:32Z",
        "Driver": "local",
        "Labels": null,
        "Mountpoint": "/var/lib/docker/volumes/app_data/_data",
        "Name": "app_data",
        "Options": null,
        "Scope": "local"
    }
]
```

### Analysis

This task shows why volumes are important in Docker. Containers are temporary, but data stored in a volume remains available independently of the container lifecycle.

In this example, the HTML file was stored in the mounted volume, so after removing the `web` container and starting `web_new`, the same page was still available.

Volumes are managed by Docker and are the preferred way to store persistent application data. Bind mounts are useful when a container needs access to a specific host directory, especially during development. Data stored only inside the container filesystem is usually lost when the container is removed.