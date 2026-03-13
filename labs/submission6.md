# Task 1

## Output of docker ps -a and docker images

`docker images ubuntu`

```
REPOSITORY   TAG       IMAGE ID       CREATED       SIZE
ubuntu       latest    bbdabce66f1b   4 weeks ago   78.1MB
```

`docker ps -a`

```
CONTAINER ID   IMAGE           COMMAND       CREATED          STATUS          PORTS     NAMES
676f1ee3d0af   ubuntu:latest   "/bin/bash"   23 seconds ago   Up 22 seconds             ubuntu_container
```

## Image size and layer count
Layers: 1
Image size: 78.1 MB


## Tar file size comparison with image size
Tar file size: 77MB
Docker image size: 78.1 MB

tar file size is less because it is compressed

## Error message from the first removal attempt



```
Error response from daemon: conflict: unable to remove repository reference "ubuntu:latest" (must force) - container 676f1ee3d0af is using its referenced image bbdabce66f1b
```

## Analysis: Why does image removal fail when a container exists? Explain the dependency relationship

Container stores the image ID it was created from, so removing the image would orphan that container’s filesystem and metadata.

## Explanation: What is included in the exported tar file?

Tar file stores image filesystem layer blobs (tar archives), the image config JSON, and a manifest that lists layers and tags. It includes image metadata, but does not include container state container metadata or external volumes

# Task 2

## Output of original Nginx welcome page

`curl http://localhost`

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

## Custom HTML content and verification via curl

`curl http://localhost`

```
<html>
<head>
<title>The best</title>
</head>
<body>
<h1>website</h1>
</body>
```

## Output of docker diff my_website_container

```
C /etc
C /etc/nginx
C /etc/nginx/conf.d
C /etc/nginx/conf.d/default.conf
C /run
C /run/nginx.pid
```


## Analysis: Explain the diff output (A=Added, C=Changed, D=Deleted)
`/etc/nginx/conf.d/default.conf`  C — nginx or the container startup modified config or metadata compared to the image.
`/run and /run/nginx.pid` are ephemeral runtime files created/updated at container start, so they appear as changed.

Custom `index.html` does not appear because I committed the running container into the image. Committed image already contains the new index.html, so a container started from that image shows no diff for that file


## Reflection: What are the advantages and disadvantages of docker commit vs Dockerfile for image creation?

docker commit

Advantages: very fast for ad hoc snapshots and exploratory changes. no need to write a Dockerfile.
Disadvantages: not reproducible, hard to review or version control, bad for automation


Dockerfile

Advantages: declarative, reproducible, versionable, reviewable, suitable for CI/CD and automation; easier to rebuild and maintain.

Disadvantages: slower to iterate for quick experiments


# Task 3

## Output of ping command showing successful connectivity

`docker exec container1 ping -c 3 container2`

```
64 bytes from 172.18.0.3: seq=0 ttl=64 time=0.073 ms
64 bytes from 172.18.0.3: seq=1 ttl=64 time=0.112 ms
64 bytes from 172.18.0.3: seq=2 ttl=64 time=0.127 ms

--- container2 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 0.073/0.104/0.127 ms
```

## Network inspection output showing both containers' IP addresses

```
[
    {
        "Name": "lab_network",
        "Id": "0ea0f70186ffc934b95f61b6abedea107b868be47f9e2f79501abbfd28a3822b",
        "Created": "2026-03-13T21:24:33.203762908+03:00",
        "Scope": "local",
        "Driver": "bridge",
        "EnableIPv4": true,
        "EnableIPv6": false,
        "IPAM": {
            "Driver": "default",
            "Options": {},
            "Config": [
                {
                    "Subnet": "172.18.0.0/16",
                    "Gateway": "172.18.0.1"
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
        "Containers": {
            "373e4ce19d4e763f288f1759eb372df7a0033d8820a1719e444316eca9c172be": {
                "Name": "container1",
                "EndpointID": "645b2bd0cf69bd6451a5cbcc5d9c485aa6baffbe5bb74ddc50f99b6a1da456d8",
                "MacAddress": "7a:01:c6:84:6c:a6",
                "IPv4Address": "172.18.0.2/16",
                "IPv6Address": ""
            },
            "9e16727029f1b04e567dd4809b9359b527ad0148f9e77dd98df754ed829ec8c6": {
                "Name": "container2",
                "EndpointID": "37c75b4011575e97482db9f565d29b902a0e5928d6c22c59c5d5d6733e38dd11",
                "MacAddress": "fa:62:39:f6:fd:ec",
                "IPv4Address": "172.18.0.3/16",
                "IPv6Address": ""
            }
        },
        "Options": {},
        "Labels": {}
    }
]
```

## DNS resolution output

```
Server:         127.0.0.11
Address:        127.0.0.11:53

Non-authoritative answer:

Non-authoritative answer:
Name:   container2
Address: 172.18.0.3
```


## Analysis: How does Docker's internal DNS enable container-to-container communication by name?

Docker runs embedded DNS server in address 127.0.0.11. When a container queries a hostname (e. g. container2), the embedded DNS returns the container’s network IP

## Comparison: What advantages does user-defined bridge networks provide over the default bridge network?

Automatic DNS name resolution for containers on the same network

Network isolation and scoped communication (separate networks don’t see each other)

Ability to attach multiple containers to multiple networks

Easier service discovery and cleaner, reproducible networking than the legacy default bridge


# Task 4

## Custom HTML content used

```
<html><body><h1>Persistent Data</h1></body></html>
```

## Output of curl showing content persists after container recreation

`curl http://localhost`

```
<html><body><h1>Persistent Data</h1></body></html>
```

## Volume inspection output showing mount point

```
[
    {
        "CreatedAt": "2026-03-13T21:30:04+03:00",
        "Driver": "local",
        "Labels": null,
        "Mountpoint": "/var/lib/docker/volumes/app_data/_data",
        "Name": "app_data",
        "Options": null,
        "Scope": "local"
    }
]
```

## Analysis: Why is data persistence important in containerized applications?

Because we might need to store some unchanged data and make changes to container itself, e.g for large DBs. This helps to cut time during updates or CI/CD


## Comparison: Explain the differences between volumes, bind mounts, and container storage. When would you use each?

Volumes: managed by docker and referenced by name. Best for persistent data, easier for backup and migration

Bind mounts: maps host directory or file into the container. Immediate reflection of host changes, useful for iterative development and debugging

Container storage: container’s internal writable filesystem layer on top of image layers. Changes only for the container lifecycle and are lost when the container is removed, cant be used for persistence.

When to use each:
- Use volumes for prod persistence and shared data.
- Use bind mounts for local development or when you must expose specific host files
- Don’t rely on the container writable layer for important data
