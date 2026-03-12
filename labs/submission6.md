# Task 1

Command: `docker ps -a`
Output: 
```
CONTAINER ID   IMAGE            COMMAND                  CREATED        STATUS                    PORTS     NAMES
6f962e62aac6   deployment-api   "uvicorn main:app --…"   5 months ago   Exited (0) 5 months ago             deployment-api-1
78e8c1d00b40   deployment-app   "streamlit run main.…"   5 months ago   Exited (0) 5 months ago             deployment-app-1
```

COmmand: `docker images ubuntu`
Output: 
```
IMAGE           ID             DISK USAGE   CONTENT SIZE   EXTRA
ubuntu:latest   bbdabce66f1b       78.1MB             0B        
```

Command: `cat /etc/os-release`
Output:
```
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
PRIVACY_POLICY_URL="https://www.ubuntu.com/legal/terms-and-policies/privacy-policy"
UBUNTU_CODENAME=noble
LOGO=ubuntu-logo
```

Command: 
```
docker save -o ubuntu_image.tar ubuntu:latest
ls -lh ubuntu_image.tar
```
Ouput:
```
Permissions Size User     Date Modified Name
.rw-------   81M vladimir 12 Mar 22:37   ubuntu_image.tar
```


Command:
```
docker rmi ubuntu:latest
```
Output:
```
Error response from daemon: conflict: unable to remove repository reference "ubuntu:latest" (must force) - container 3857d0d9560f is using its referenced image bbdabce66f1b
```

## Why does image removal fail when a container exists?

Docker does not allow deleting an image that is currently being used by an existing container. Containers are created from images 
and rely on them as their base filesystem. Removing the image while a container depends on it would break the container's filesystem layers.

So the container must be removed before the image can be deleted.

Tar File Size vs Image Size

The exported tar file is roughly the same size as the image. This is because the tar archive contains the same image layers stored locally.

## What is included in the exported tar file?

The exported tar archive contains:

Image filesystem layers

Image metadata

Configuration files

Manifest describing how layers are assembled

# Task 2



Command:
```
curl http://localhost

```
Output:
```
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

Command:
```
docker cp index.html nginx_container:/usr/share/nginx/html/
curl http://localhost
```
Output:
```
Successfully copied 2.05kB to nginx_container:/usr/share/nginx/html/
<html>
<head>
<title>The best</title>
</head>
<body>
<h1>website</h1>
</body>
</html>

```

Command:
```
docker diff my_website_container
```
Output:
```
C /etc
C /etc/nginx
C /etc/nginx/conf.d
C /etc/nginx/conf.d/default.conf
C /run
C /run/nginx.pid
```

### Diff output analysis
The diff only shows `C` (Changed) nginx specific files. These get modified when the container starts up 
(the PID file is created at launch, configs get touched). 

### Docker commit vs Dockerfile 

Using `docker commit` is useful when you just want to quickly save what your current container's state, 
but the there's no history of changes. In Dockerfile every step is written down, you can version it with git. 

# Task 3

Command:
```
docker network create lab_network
docker network ls

```
Output:
```
NETWORK ID     NAME             DRIVER    SCOPE
cd1b36feb14a   bridge           bridge    local
ede0d3c984f1   deployment_net   bridge    local
c4e15a991180   host             host      local
06b6488b050b   lab_network      bridge    local
e421f5d5de90   none             null      local
```

Command:
```
docker exec container1 ping -c 3 container2

```
Output:
```
PING container2 (172.20.0.3): 56 data bytes
64 bytes from 172.20.0.3: seq=0 ttl=64 time=0.076 ms
64 bytes from 172.20.0.3: seq=1 ttl=64 time=0.141 ms
64 bytes from 172.20.0.3: seq=2 ttl=64 time=0.143 ms

--- container2 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 0.076/0.120/0.143 ms
```

Command:
```
docker network inspect lab_network

```
Output:
```
[
    {
        "Name": "lab_network",
        "Id": "06b6488b050b7e44ccc2205ec1abc15e88fc062ea8f04c01df2fb9020110da8a",
        "Created": "2026-03-12T23:03:35.177675103+03:00",
        "Scope": "local",
        "Driver": "bridge",
        "EnableIPv4": true,
        "EnableIPv6": false,
        "IPAM": {
            "Driver": "default",
            "Options": {},
            "Config": [
                {
                    "Subnet": "172.20.0.0/16",
                    "Gateway": "172.20.0.1"
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
        "Options": {},
        "Labels": {},
        "Containers": {
            "1948b6a5c4c76a95554f704c63c7992ddfb3bf85820ac1948be525b0e339fe39": {
                "Name": "container2",
                "EndpointID": "67560d44755cae287f16026c1a5abb78fa981dd7484aa9aad13053a1eda94b42",
                "MacAddress": "ae:dd:63:74:c9:f5",
                "IPv4Address": "172.20.0.3/16",
                "IPv6Address": ""
            },
            "424e47ba84f059755f88e73265a2b29444fad14f4d617077ae357383b22c6092": {
                "Name": "container1",
                "EndpointID": "21b4419b05b02675585ed43e37be3c7487a2b5c7f23d66ee3a0b8d012cb0de56",
                "MacAddress": "c2:26:33:0c:1f:68",
                "IPv4Address": "172.20.0.2/16",
                "IPv6Address": ""
            }
        },
        "Status": {
            "IPAM": {
                "Subnets": {
                    "172.20.0.0/16": {
                        "IPsInUse": 5,
                        "DynamicIPsAvailable": 65531
                    }
                }
            }
        }
    }
]

```

Command:
```
docker exec container1 nslookup container2
```
Output:
```
Server:		127.0.0.11
Address:	127.0.0.11:53

Non-authoritative answer:

Non-authoritative answer:
Name:	container2
Address: 172.20.0.3
```

## Analysis
Docker provides an internal DNS server for user-defined networks. When containers are attached to the same network, Docker automatically registers their container names as DNS records.

### User-defined Bridge vs Default Bridge
***User-defined Bridge**

Advantages:

Automatic DNS resolution

Better container isolation

Easier container-to-container communication

More flexible configuration

**Default Bridge**

Limitations:

No automatic DNS resolution

Requires manual linking or IP usage

Less flexible networking configuration

# Task 4

Command:
```
docker volume create app_data
docker volume ls

```
Output:
```
app_data
DRIVER    VOLUME NAME
local     aeef7a32a449368fe1d5aaa832259066d9e784b88aec834aaafc008bfde998ca
local     app_data
local     bd9617819300bb18d19a936d50722a6091fa4def56c01a4fb2b24dc785bee4e1

```

Command:
```
docker cp index.html web:/usr/share/nginx/html/
curl http://localhost
```
Output:
```
Successfully copied 2.05kB to web:/usr/share/nginx/html/
<html><body><h1>Persistent Data</h1></body></html>
```

Command:
```
docker volume inspect app_data

```
Output:
```
[
    {
        "CreatedAt": "2026-03-12T23:08:52+03:00",
        "Driver": "local",
        "Labels": null,
        "Mountpoint": "/var/lib/docker/volumes/app_data/_data",
        "Name": "app_data",
        "Options": null,
        "Scope": "local"
    }
]
```

# Analysis
### Why is data persistence important?

Containers are ephemeral, meaning their internal storage disappears when the container is removed. 
Persistent storage ensures that important data such as:
databases

user uploads

application state

is not lost when containers restart or are recreated.

### Volumes vs bind mounts vs container storage 
**Volumes** are managed by Docker itself and stored somewhere on the host. They stick around even after containers are gone, 
so they're great for anything you need to keep. 
**Bind mounts** let you map a specific folder from your host into a container — handy during development when you want live code changes to show up inside the container. 
**Container storage** is just the writable layer inside the container itself; it disappears when the container is deleted. 
Use volumes for data you care about, bind mounts for development convenience, and don't rely on container storage for anything permanent.
