# Lab 6

## Task 1

Command:

```sh
docker ps -a
```

Output:

```text
CONTAINER ID   IMAGE                COMMAND                  CREATED       STATUS                        PORTS                                         NAMES
b49e46a5eb18   postgres:16-alpine   "docker-entrypoint.s..."   3 weeks ago   Up About a minute (healthy)   0.0.0.0:5432->5432/tcp, [::]:5432->5432/tcp   inno_postgres
```

### Pull and inspect Ubuntu image

Commands:

```sh
docker pull ubuntu:latest
docker images ubuntu
docker image inspect ubuntu:latest --format "Layers={{len .RootFS.Layers}} SizeBytes={{.Size}}"
```

Output:

```text
latest: Pulling from library/ubuntu
Digest: sha256:f3d28607ddd78734bb7f71f117f3c6706c666b8b76cbff7c9ff6e5718d46ff64
Status: Downloaded newer image for ubuntu:latest
docker.io/library/ubuntu:latest

IMAGE           ID             DISK USAGE   CONTENT SIZE   EXTRA
ubuntu:latest   f3d28607ddd7        160MB         45.3MB

Layers=2 SizeBytes=41567720
```

The `ubuntu:latest` image has 2 layers. Docker shows the content size as `45.3MB`. The inspect command shows `41,567,720` bytes.

### Container exploration

Command used to save the output:

```sh
docker run --name ubuntu_container ubuntu:latest sh -c "cat /etc/os-release; echo '--- processes ---'; ps aux"
```

Output:

```text
PRETTY_NAME="Ubuntu 26.04 LTS"
NAME="Ubuntu"
VERSION_ID="26.04"
VERSION="26.04 (Resolute Raccoon)"
VERSION_CODENAME=resolute
ID=ubuntu
ID_LIKE=debian
HOME_URL="https://www.ubuntu.com/"
SUPPORT_URL="https://help.ubuntu.com/"
BUG_REPORT_URL="https://bugs.launchpad.net/ubuntu/"
PRIVACY_POLICY_URL="https://www.ubuntu.com/legal/terms-and-policies/privacy-policy"
UBUNTU_CODENAME=resolute
LOGO=ubuntu-logo
--- processes ---
USER         PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root           1 11.7  0.0   2880  1256 ?        Ss   11:12   0:00 sh -c cat /etc/os-release; echo '--- processes ---'; ps aux
root           8  0.0  0.0   6752  4088 ?        R    11:12   0:00 ps aux
```

### Image export and removal

Commands:

```sh
docker save -o ubuntu_image.tar ubuntu:latest
Get-Item .\ubuntu_image.tar | Format-List Name,Length
docker rmi ubuntu:latest
docker rm ubuntu_container
docker rmi ubuntu:latest
```

Output:

```text
Name   : ubuntu_image.tar
Length : 45284864

Error response from daemon: conflict: unable to delete ubuntu:latest (must be forced) - container ba88f46f01b5 is using its referenced image f3d28607ddd7

ubuntu_container
Untagged: ubuntu:latest
Deleted: sha256:f3d28607ddd78734bb7f71f117f3c6706c666b8b76cbff7c9ff6e5718d46ff64
```

The exported tar file was `45,284,864` bytes. This is close to the Docker content size, `45.3MB`. The disk usage value is higher because Docker also stores unpacked image data and extra metadata.

The first image removal failed because `ubuntu_container` still used the image. A container depends on the image it was created from, even after it stops. Docker does not remove the image normally while a container still references it.

The tar file from `docker save` contains the image manifest, image config, tag information, and filesystem layers. This is enough to load the image again with `docker load`.

## Task 2 - Custom Image Creation & Analysis

### Original Nginx container

Commands:

```sh
docker run -d -p 80:80 --name nginx_container nginx
curl http://localhost
```

output:

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
<p>If you see this page, nginx is successfully installed and working.
Further configuration is required for the web server, reverse proxy, 
API gateway, load balancer, content cache, or other features.</p>

<p>For online documentation and support please refer to
<a href="https://nginx.org/">nginx.org</a>.<br/>
To engage with the community please visit
<a href="https://community.nginx.org/">community.nginx.org</a>.<br/>
For enterprise grade support, professional services, additional 
security features and capabilities please refer to
<a href="https://f5.com/nginx">f5.com/nginx</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
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
<p>If you see this page, nginx is successfully installed and working.
Further configuration is required for the web server, reverse proxy, 
API gateway, load balancer, content cache, or other features.</p>

<p>For online documentation and support please refer to
<a href="https://nginx.org/">nginx.org</a>.<br/>
To engage with the community please visit
<a href="https://community.nginx.org/">community.nginx.org</a>.<br/>
For enterprise grade support, professional services, additional 
security features and capabilities please refer to
<a href="https://f5.com/nginx">f5.com/nginx</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>

```

### Custom page

Custom `index.html`:

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

Commands:

```sh
docker cp index.html nginx_container:/usr/share/nginx/html/
curl http://localhost
```

Output:

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

### Commit and run custom image

Commands:

```sh
docker commit nginx_container my_website:latest
docker images my_website
docker rm -f nginx_container
docker run -d -p 80:80 --name my_website_container my_website:latest
curl http://localhost
```

Output:

```text
sha256:12ab4b9487fa03e6874d86d85dfb1f1a0bd195f6e1120cc9b92198b372d07ceb

IMAGE               ID             DISK USAGE   CONTENT SIZE   EXTRA
my_website:latest   12ab4b9487fa        238MB         63.1MB

<html>
<head>
<title>The best</title>
</head>
<body>
<h1>website</h1>
</body>
</html>
```

### Filesystem diff

Command:

```sh
docker diff my_website_container
```

Output:

```text
C /etc
C /etc/nginx
C /etc/nginx/conf.d
C /etc/nginx/conf.d/default.conf
C /run
C /run/nginx.pid
```

In `docker diff`, `A` means added, `C` means changed, and `D` means deleted. Here Docker shows changed Nginx config/runtime files and the PID file. The custom `index.html` is not shown because it was already saved into `my_website:latest` before this container was started.

`docker commit` is useful for quick tests because it saves the current container state. The disadvantage is that the changes are not easy to review or repeat. A Dockerfile is better for real projects because it clearly describes each step and can be rebuilt in the same way later.

## Task 3 - Container Networking & Service Discovery

### Network creation

Commands:

```sh
docker network create lab_network
docker network ls
```

Output:

```text
c9708d974bac21197367a625735f28719339b8979ce268112b0ad614984c1633

NETWORK ID     NAME                    DRIVER    SCOPE
2f95d79512b2   bridge                  bridge    local
96f36494390d   host                    host      local
482c91086cc3   innodeadlines_default   bridge    local
c9708d974bac   lab_network             bridge    local
786816cf8ba8   none                    null      local
```

### Connected containers

Commands:

```sh
docker run -dit --network lab_network --name container1 alpine ash
docker run -dit --network lab_network --name container2 alpine ash
```

Output:

```text
e44ffa5a3727ff517be6cae74ab91e082a5a384f35007ca6d1157765abb4a8ed
59f6807639eb6690fb2357e74c6e1ee6e13130911826a322543b3dca16474d6e
```

### Connectivity and DNS

Command:

```sh
docker exec container1 ping -c 3 container2
```

Output:

```text
PING container2 (172.19.0.3): 56 data bytes
64 bytes from 172.19.0.3: seq=0 ttl=64 time=0.168 ms
64 bytes from 172.19.0.3: seq=1 ttl=64 time=0.204 ms
64 bytes from 172.19.0.3: seq=2 ttl=64 time=0.114 ms

--- container2 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 0.114/0.162/0.204 ms
```

Command:

```sh
docker network inspect lab_network --format "{{json .Containers}}"
```

Output:

```json
{
  "59f6807639eb6690fb2357e74c6e1ee6e13130911826a322543b3dca16474d6e": {
    "Name": "container2",
    "EndpointID": "b8af03e532860c88d00e1a7d3a5bce914a1a0e3fec3d88f92a6fdb94f70faa55",
    "MacAddress": "3a:92:ac:6c:c2:48",
    "IPv4Address": "172.19.0.3/16",
    "IPv6Address": ""
  },
  "e44ffa5a3727ff517be6cae74ab91e082a5a384f35007ca6d1157765abb4a8ed": {
    "Name": "container1",
    "EndpointID": "c794e61f6acf4c663ef1acf773306967cac06c3164aaed08f44b2410fac972ce",
    "MacAddress": "42:6a:17:d2:a7:07",
    "IPv4Address": "172.19.0.2/16",
    "IPv6Address": ""
  }
}
```

Command:

```sh
docker exec container1 nslookup container2
```

Output:

```text
Server:         127.0.0.11
Address:        127.0.0.11:53

Non-authoritative answer:
Name:   container2
Address: 172.19.0.3
```

Docker gives containers an internal DNS server at `127.0.0.11`. On a user-defined network, Docker can resolve container names. So `container1` can reach `container2` by name instead of using its IP address directly.

User-defined bridge networks are better for several connected containers. They support name-based DNS, provide better isolation, and are easier to manage. The default bridge is fine for simple tests, but it is less convenient for service discovery.

## Task 4 - Data Persistence with Volumes

### Volume creation

Commands:

```sh
docker volume create app_data
docker volume ls
```

Output:

```text
app_data
DRIVER    VOLUME NAME
local     app_data
local     innodeadlines_inno_pg_data
```

### Write custom content to the volume

Custom `index.html`:

```html
<html><body><h1>Persistent Data</h1></body></html>
```

Commands:

```sh
docker run -d -p 80:80 -v app_data:/usr/share/nginx/html --name web nginx
docker cp index.html web:/usr/share/nginx/html/
curl http://localhost
```

Output:

```text
027a9b697e0dfbe3ba0d2163a5b9a58aae139d38908398de007e5ff8bc23dad6

<html><body><h1>Persistent Data</h1></body></html>
```

### Verify persistence after container recreation

Commands:

```sh
docker stop web
docker rm web
docker run -d -p 80:80 -v app_data:/usr/share/nginx/html --name web_new nginx
curl http://localhost
```

Output:

```text
web
web
6bf38c98208ccaed78c954ebe510fc7da31bab1a312e0720a9a145057c047ddd
<html><body><h1>Persistent Data</h1></body></html>
```

Command:

```sh
docker volume inspect app_data
```

Output:

```json
[
  {
    "CreatedAt": "2026-05-16T11:13:57Z",
    "Driver": "local",
    "Labels": null,
    "Mountpoint": "/var/lib/docker/volumes/app_data/_data",
    "Name": "app_data",
    "Options": null,
    "Scope": "local"
  }
]
```

Data persistence is important because containers can be removed and recreated at any time. Application data, such as files or database data, should remain intact.

Volumes are managed by Docker. They are the best default choice for persistent container data. Bind mounts connect a specific host folder to a container, which is useful during development. Container storage is the writable layer inside a container. It is good for temporary changes, but it is removed with the container, so it should not store important data.