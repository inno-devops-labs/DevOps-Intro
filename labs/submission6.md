# **Lab 6 — Container Fundamentals with Docker**

## **Task 1 — Container Lifecycle & Image Management**

### **Output of `docker ps -a` and `docker images`**

```bash
Maksim@DESKTOP-JTHSL99 MINGW64 ~/Desktop/DO/DevOps-Intro/labs/temp (feature/lab5)
$ docker ps -a
CONTAINER ID   IMAGE                           COMMAND                  CREATED       STATUS                     PORTS     NAMES
e48052e309b9   citusdata/citus:13.0            "docker-entrypoint.s…"   3 days ago    Exited (0) 5 minutes ago             citus
3614efb64c4a   hortonworks/sandbox-proxy:1.0   "nginx -g 'daemon of…"   7 weeks ago   Exited (0) 7 weeks ago               hungry_herschel
b3c0a917be54   hortonworks/sandbox-hdp:2.6.5   "/usr/sbin/init"         7 weeks ago   Exited (137) 7 weeks ago             recursing_bouman
```

```bash
Maksim@DESKTOP-JTHSL99 MINGW64 ~/Desktop/DO/DevOps-Intro/labs/temp (feature/lab5)
$ docker images ubuntu
                                                            i Info →   U  In Use
IMAGE           ID             DISK USAGE   CONTENT SIZE   EXTRA
ubuntu:latest   d1e2e92c075e        119MB         31.7MB
```


### **Image size and layer count**

* Image size is `119 MB`, it was known via `docker images ubuntu`

* The layer count is `1`, it was known via `docker inspect ubuntu:latest`: 

```bash
Maksim@DESKTOP-JTHSL99 MINGW64 ~/Desktop/DO/DevOps-Intro/labs/temp (feature/lab5)
$ docker inspect ubuntu:latest
[
    {
        "Id": "sha256:d1e2e92c075e5ca139d51a140fff46f84315c0fdce203eab2807c7e495eff4f9",
        "RepoTags": [
            "ubuntu:latest"
        ],
        "RepoDigests": [
            "ubuntu@sha256:d1e2e92c075e5ca139d51a140fff46f84315c0fdce203eab2807c7e495eff4f9"
        ],
        "Created": "2026-02-10T16:49:57.226767398Z",
        "Config": {
            "Env": [
                "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
            ],
            "Cmd": [
                "/bin/bash"
            ],
            "Labels": {
                "org.opencontainers.image.ref.name": "ubuntu",
                "org.opencontainers.image.version": "24.04"
            }
        },
        "Architecture": "amd64",
        "Os": "linux",
        "Size": 29737017,
        "RootFS": {
            "Type": "layers",
            "Layers": [
                "sha256:efafae78d70c98626c521c246827389128e7d7ea442db31bc433934647f0c791"
            ]
        },
        "Metadata": {
            "LastTagTime": "2026-03-11T19:55:19.500893175Z"
        },
        "Descriptor": {
            "mediaType": "application/vnd.oci.image.index.v1+json",
            "digest": "sha256:d1e2e92c075e5ca139d51a140fff46f84315c0fdce203eab2807c7e495eff4f9",
            "size": 6688
        }
    }
]
```

* According to the `ls -lh ubuntu_image.tar` output, the tar size is `31 MB`. The image size is `119 MB`

```bash
Maksim@DESKTOP-JTHSL99 MINGW64 ~/Desktop/DO/DevOps-Intro/labs/temp (feature/lab5)
$ ls -lh ubuntu_image.tar
-rw-r--r-- 1 Maksim 197121 31M Mar 11 22:45 ubuntu_image.tar
```

* Error message from the first removal attempt:

```bash
Maksim@DESKTOP-JTHSL99 MINGW64 ~/Desktop/DO/DevOps-Intro/labs/temp (feature/lab5)
$ docker rmi ubuntu:latest
Error response from daemon: conflict: unable to delete ubuntu:latest (must be forced) - container aa3f046032c8 is using its referenced image d1e2e92c075e
```

* Analysis of the error: since the container that is created from this image exists, the image itself can not be removed. The image provides all necessary layers for the container. Such deletion can cause problems with launching the container again.

* The contents of the `tar` file is the information that is needed to recreate the image with the corresponding history. It contains all its layers, a configuration file, and a file containing information about the layers order.


## **Task 2 — Custom Image Creation & Analysis**

* Output of original Nginx welcome page

```bash
Maksim@DESKTOP-JTHSL99 MINGW64 ~/Desktop/DO/DevOps-Intro/labs/temp (feature/lab5)
$ curl http://localhost
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

* Custom HTML content and verification via curl

```bash
Maksim@DESKTOP-JTHSL99 MINGW64 ~/Desktop/DO/DevOps-Intro/labs/temp (feature/lab5)
$ docker cp index.html nginx_container:/usr/share/nginx/html/
Successfully copied 2.05kB to nginx_container:/usr/share/nginx/html/

Maksim@DESKTOP-JTHSL99 MINGW64 ~/Desktop/DO/DevOps-Intro/labs/temp (feature/lab5)
$ curl http://localhost
<html>
<head>
<title>The best</title>
</head>
<body>
<h1>website</h1>
</body>
</html>
```

* Output of `docker diff my_website_container`

```bash
Maksim@DESKTOP-JTHSL99 MINGW64 ~/Desktop/DO/DevOps-Intro/labs/temp (feature/lab5)
$ docker diff my_website_container
C /run
C /run/nginx.pid
C /etc
C /etc/nginx
C /etc/nginx/conf.d
C /etc/nginx/conf.d/default.conf
```

* The output of `docker diff my_website_container` shows that service files and directories have changed in the container (`nginx.pid` was added in `/run`), and configuration files were modified in `/etc/nginx`

* `docker commit` is convinient for experiments, but is is not reproducible and hard to maintain. On the other hand, `Dockerfile` is reproducible and automated, allowing to reach transparent maintaining. However, builds can be slower.

## **Task 3 — Container Networking & Service Discovery**

* The `docker exec container1 ping -c 3 container2` output

```bash
Maksim@DESKTOP-JTHSL99 MINGW64 ~/Desktop/DO/DevOps-Intro/labs/temp (feature/lab5)
$ docker exec container1 ping -c 3 container2
PING container2 (172.19.0.3): 56 data bytes
64 bytes from 172.19.0.3: seq=0 ttl=64 time=2.186 ms
64 bytes from 172.19.0.3: seq=1 ttl=64 time=0.176 ms
64 bytes from 172.19.0.3: seq=2 ttl=64 time=0.286 ms

--- container2 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 0.176/0.882/2.186 ms
```

* Network inspection output

```bash
Maksim@DESKTOP-JTHSL99 MINGW64 ~/Desktop/DO/DevOps-Intro/labs/temp (feature/lab5)
$ docker network inspect lab_network
[
    {
        "Name": "lab_network",
        "Id": "e28756edf59f219db65cff4a04b9589dceeded181982043157737aa8cc3f0378",
        "Created": "2026-03-13T20:28:02.450402551Z",
        "Scope": "local",
        "Driver": "bridge",
        "EnableIPv4": true,
        "EnableIPv6": false,
        "IPAM": {
            "Driver": "default",
            "Options": {},
            "Config": [
                {
                    "Subnet": "172.19.0.0/16",
                    "IPRange": "",
                    "Gateway": "172.19.0.1"
                }
            ]
        },
        "Internal": false,
        "Attachable": false,
        "Ingress": false,
        "ConfigFrom": {
            "Network": ""
        },
        "ConfigOnly": false,
        "Options": {
            "com.docker.network.enable_ipv4": "true",
            "com.docker.network.enable_ipv6": "false"
        },
        "Labels": {},
        "Containers": {
            "0c18c337d3fa30df48352e74a9a66a76f788390c2cb173578abb460d87b93b5f": {
                "Name": "container1",
                "EndpointID": "6b808f7c523eaed9456984b536caa1d76c4484a352f02c8bd59cafc24fa32228",
                "MacAddress": "56:7a:45:47:17:9c",
                "IPv4Address": "172.19.0.2/16",
                "IPv6Address": ""
            },
            "5da9063a8034f18f3ddadb11cc618d4a9ccdf19af3e7d0cd4fa90334a7aea92f": {
                "Name": "container2",
                "EndpointID": "d85e601d7d50cd27c6300fbee1fd16f68c5edc2c2923d94fa36b4c5b0d9a134b",
                "MacAddress": "4e:03:ff:80:4a:61",
                "IPv4Address": "172.19.0.3/16",
                "IPv6Address": ""
            }
        },
        "Status": {
            "IPAM": {
                "Subnets": {
                    "172.19.0.0/16": {
                        "IPsInUse": 5,
                        "DynamicIPsAvailable": 65531
                    }
                }
            }
        }
    }
]
```
* DNS resolution output

```bash
Maksim@DESKTOP-JTHSL99 MINGW64 ~/Desktop/DO/DevOps-Intro/labs/temp (feature/lab5)
$ docker exec container1 nslookup container2
Server:         127.0.0.11
Address:        127.0.0.11:53

Non-authoritative answer:

Non-authoritative answer:
Name:   container2
Address: 172.19.0.3
```

* Analysis: Docker runs an DNS server inside each container, containers are forwarded to it while accessing each other by name. The server provides the corresponding IP addressed

* Comparison: containers can ping each other by name without unnecessary communications. Also, user-defined networks allow to disconnect containers during runtime.


## **Task 4 — Data Persistence with Volumes**

* Custom HTML content

```html
<html><body><h1>Persistent Data</h1></body></html>
```

* Curl output

```bash
Maksim@DESKTOP-JTHSL99 MINGW64 ~/Desktop/DO/DevOps-Intro/labs/temp (feature/lab5)
$ docker stop web && docker rm web
web
web

Maksim@DESKTOP-JTHSL99 MINGW64 ~/Desktop/DO/DevOps-Intro/labs/temp (feature/lab5)
$ docker run -d -p 80:80 -v app_data:/usr/share/nginx/html --name web_new nginx
de84c5e1080c64cb5dbb7763d779bc933fa103e2221eed3fb1c01eea4fb1ea3d

Maksim@DESKTOP-JTHSL99 MINGW64 ~/Desktop/DO/DevOps-Intro/labs/temp (feature/lab5)
$ curl http://localhost
<html><body><h1>Persistent Data</h1></body></html>

Maksim@DESKTOP-JTHSL99 MINGW64 ~/Desktop/DO/DevOps-Intro/labs/temp (feature/lab5)
$ docker volume inspect app_data
[
    {
        "CreatedAt": "2026-03-13T20:38:02Z",
        "Driver": "local",
        "Labels": null,
        "Mountpoint": "/var/lib/docker/volumes/app_data/_data",
        "Name": "app_data",
        "Options": null,
        "Scope": "local"
    }
]
```

* Mount point: /var/lib/docker/volumes/app_data/_data

* Analysis: after deleting a container, its data is lost. 

* Comparison: container storage is for a temporary storage that is created while launcing a container. Boind mounts are useful for live updates. Volumes are used for production.