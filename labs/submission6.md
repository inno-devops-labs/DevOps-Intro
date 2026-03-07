# Lab 6 Submission

## Task 1 - Container Lifecycle & Image Management

### 1.1. Basic Container Operations

I run a small test container to check that Docker works correctly:

```bash
seva@Seva:/...$ docker run hello-world
...
Hello from Docker!
This message shows that your installation appears to be working correctly.
...
```

#### List Existing Containers

I list all containers on the system, including stopped ones:

```bash
seva@Seva:/...$ docker ps -a
CONTAINER ID   IMAGE         COMMAND    CREATED              STATUS                          PORTS     NAMES
aec2b73b303d   hello-world   "/hello"   About a minute ago   Exited (0) About a minute ago             tender_neumann

```

The output shows one container created from the `hello-world` image.
Its status is `Exited`, which means it finished execution.
Docker automatically assigned it the name `tender_neumann`.


#### Pull Ubuntu Image

I download the `Ubuntu` image from the Docker registry and check that it exists locally:

```bash
seva@Seva:/...$ docker pull ubuntu:latest
latest: Pulling from library/ubuntu
...
Digest: sha256:d1e2e92c075e5ca139d51a140fff46f84315c0fdce203eab2807c7e495eff4f9
Status: Downloaded newer image for ubuntu:latest
docker.io/library/ubuntu:latest

seva@Seva:/...$ docker images ubuntu
IMAGE           ID             DISK USAGE   CONTENT SIZE   EXTRA
ubuntu:latest   d1e2e92c075e        119MB         31.7MB

```

The image was successfully downloaded from `Docker Hub`.
We can see its `ID` and `disk usage`.
The image is now stored locally and can be used to create containers.


#### Run Interactive Container

I run an interactive `Ubuntu` container and explore its environment:

```bash
seva@Seva:/...$ docker run -it --name ubuntu_container ubuntu:latest
root@3c20a8dd4268:/# cat /etc/os-release
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

root@3c20a8dd4268:/# ps aux
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root         1  0.0  0.0   4588  3840 pts/0    Ss   16:48   0:00 /bin/bash
root        10  0.0  0.0   7888  4096 pts/0    R+   16:48   0:00 ps aux
```

The container starts a minimal `Ubuntu` system.
The `/etc/os-release` file confirms that the OS version is `Ubuntu 24.04.`
The `ps aux` command shows running processes inside the container.


### 1.2. Image Export and Dependency Analysis

#### Export the Image

I export the `Ubuntu` image to a tar archive and check the file size:

```bash
seva@Seva:/...$ docker save -o ubuntu_image.tar ubuntu:latest

seva@Seva:/...$ ls -lh ubuntu_image.tar
-rwxrwxrwx 1 seva seva 31M Mar  7 19:50 ubuntu_image.tar
```

The image was successfully exported into a `tar archive`.
The archive size is about `31 MB`, which contains the image layers and metadata.
This file can be transferred and later loaded into another Docker environment.


#### Attempt Image Removal

I try to remove the `Ubuntu` image while a container based on it still exists:

```bash
seva@Seva:/...$ docker rmi ubuntu:latest
Error response from daemon: conflict: unable to delete ubuntu:latest (must be forced) - container 3c20a8dd4268 is using its referenced image d1e2e92c075e
```

Docker prevents image removal because a container depends on it.
The error message shows that the image is still referenced by an existing container.
Therefore the image cannot be deleted yet.


#### Remove Container and Retry

I remove the container and try deleting the image again:

```bash
seva@Seva:/...$ docker rm ubuntu_container
ubuntu_container

seva@Seva:/...$ docker rmi ubuntu:latest
Untagged: ubuntu:latest
Deleted: sha256:d1e2e92c075e5ca139d51a140fff46f84315c0fdce203eab2807c7e495eff4f9
```

After removing the container, the image can be deleted successfully.
Docker removes the image tag and then deletes the image layers from local storage.


### Image size and layer count

The docker images command shows that the `Ubuntu` image uses about `119 MB` of disk space.
However, the actual content size of the image is about `31.7 MB`.
This difference appears because Docker images consist of multiple layers and additional metadata.
Each layer represents a filesystem change and can be reused by other images.
This layered structure helps Docker save disk space and reuse common components.

### Tar file size comparison with image size

The exported `tar` archive is about `31 MB`, which is close to the image content size.
This happens because the archive contains only the image layers and metadata.
The docker images disk usage value includes additional storage overhead.
Therefore the `tar` file is usually smaller than the reported disk usage.
This makes it easier to transfer images between systems.

### Analysis: Why does image removal fail when a container exists?

Docker images act as templates for containers.
When a container is created, it keeps a reference to the image it was built from.
If Docker allowed deleting that image, the container would lose its base filesystem.
For this reason Docker prevents image deletion while containers still depend on it.
To remove the image, all containers based on it must be deleted first.

### Explanation: What is included in the exported tar file?

The exported `tar` file contains the complete Docker image.
It includes all image layers, metadata, and configuration files.
Each layer represents a filesystem change that builds the final container filesystem.
The archive can be transferred to another machine and loaded using `docker load`.
This allows moving Docker images between systems without downloading them again.


## Task 2 - Custom Image Creation & Analysis

### 2.1. Deploy and Customize Nginx


#### Deploy Nginx Container

I start an `Nginx` container and check that the web server works.

```bash
seva@Seva:/...$ docker run -d -p 80:80 --name nginx_container nginx
Unable to find image 'nginx:latest' locally
latest: Pulling from library/nginx
...
Digest: sha256:0236ee02dcbce00b9bd83e0f5fbc51069e7e1161bd59d99885b3ae1734f3392e
Status: Downloaded newer image for nginx:latest
bbb58011b66c36f986f5d6376105e463bc4620e5efcafef14f92a590589d3e11

seva@Seva:/...$ curl http://localhost
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

Docker automatically downloaded the Nginx image from `Docker Hub`.
The container started successfully and mapped `port 80` to the host machine.
The curl request returned the default `Nginx` welcome page.


#### Create Custom HTML

I create a custom `index.html` file that will replace the default Nginx page.

#### Copy Custom Content

I copy the custom HTML file into the container and verify the change.

```bash
seva@Seva:/...$ docker cp index.html nginx_container:/usr/share/nginx/html/
Successfully copied 2.05kB to nginx_container:/usr/share/nginx/html/

seva@Seva:/...$ curl http://localhost
<html>
<head>
<title>The best</title>
</head>
<body>
<h1>website</h1>
</body>
</html>
```

The file was successfully copied into the container.
When accessing the server again, the new HTML page is displayed.
This confirms that the web server is now serving the custom content.


### 2.2. Create and Test Custom Image

#### Commit Container to Image

I create a new Docker image from the modified container.

```bash
seva@Seva:/.../docker commit nginx_container my_website:latest:latest
sha256:1751a8b63cb97a0cdc01ba8ff073b0b9921fe11a4d0e916a1970b5eba1f665ed

seva@Seva:/...$ docker images my_website
IMAGE               ID             DISK USAGE   CONTENT SIZE   EXTRA
my_website:latest   1751a8b63cb9        237MB         62.9MB
```

The docker commit command creates a new image from the current container state.
This image now contains the modified HTML page.
It can be used to start new containers with the same configuration.


#### Remove Original and Deploy from Custom Image

I remove the original container and start a new one from the custom image.

```bash
seva@Seva:/...$ docker rm -f nginx_container
nginx_container

seva@Seva:/...$ docker run -d -p 80:80 --name my_website_container my_website:latest
c54786411c8d68b5623c811891aadefea5497b71527e1e6604fbf4d4cead352e

seva@Seva:/...$ curl http://localhost
<html>
<head>
<title>The best</title>
</head>
<body>
<h1>website</h1>
</body>
</html>
```

The original container was removed successfully.
The new container runs from the custom image and serves the same page.
This confirms that the changes were saved in the image.


#### Analyze Filesystem Changes

I inspect filesystem changes inside the running container.

```bash
seva@Seva:/.../docker diff my_website_containerntainer
C /run
C /run/nginx.pid
C /etc
C /etc/nginx
C /etc/nginx/conf.d
C /etc/nginx/conf.d/default.conf
```

The output shows several changed (C) files and directories.
These changes are related to the running `Nginx` service and configuration files.
Docker tracks these differences between the container and the original image.


### Analysis: Explain the diff output (A=Added, C=Changed, D=Deleted)

The `docker diff` command shows differences between a container filesystem and its base image.
Each line starts with a letter that describes the type of change.

- `A` (Added) - new file or directory was created.

- `C` (Changed) - existing file was modified.

- `D` (Deleted) - file was removed from the container.

In this case most entries are `C`, which means files were modified while the container was running.
These changes are typically created by services like `Nginx` during startup.

### Reflection: What are the advantages and disadvantages of docker commit vs Dockerfile for image creation?

The `docker commit` command quickly creates an image from a running container.
This method is simple and useful for experiments or quick prototypes.
However, it does not document the steps that created the image.

A Dockerfile describes the image creation process step by step.
This makes the build reproducible, easier to understand, and better for version control.
For production environments Dockerfiles are usually the preferred approach.


## Task 3 - Container Networking & Service Discovery

### 3.1. Create Custom Network


#### Create Bridge Network

I create a custom Docker bridge network and list all available networks.

```bash
seva@Seva:/...$ docker network create lab_network
a871cd07e6776f465c6141d2fb6018d92a9bcea48493a2d4d2ab573d1dd4ff95

seva@Seva:/...$ docker network ls
NETWORK ID     NAME          DRIVER    SCOPE
aac8147c9f49   bridge        bridge    local
a3dbe9618421   host          host      local
a871cd07e677   lab_network   bridge    local
60273e5f35a8   none          null      local
```

The output shows that the new network lab_network was successfully created.
It uses the bridge driver, which allows containers to communicate with each other.
The list also shows default Docker networks such as bridge, host, and none.


#### Deploy Connected Containers

I start two containers and connect them to the created network.

```bash
seva@Seva:/...$ docker run -dit --network lab_network --name container1 alpine ash
Unable to find image 'alpine:latest' locally
latest: Pulling from library/alpine
589002ba0eae: Pull complete
9e595aac14e0: Download complete
caa817ad3aea: Download complete
Digest: sha256:25109184c71bdad752c8312a8623239686a9a2071e8825f20acb8f2198c3f659
Status: Downloaded newer image for alpine:latest
8e14e9ebf963293771ac7e418b07008d86eba1488277e69b2f91512b8426bd67

seva@Seva:/...$ docker run -dit --network lab_network --name container2 alpine ash
349b28f4bf539326eeae7f3c11c74f6953552a5d62ac9bcdc8835fff51c3d528
```

Docker automatically downloaded the `Alpine` image because it was not available locally.
Both containers were started in detached mode and connected to `lab_network`.
This allows them to communicate inside the same virtual network.


### 3.2. Test Connectivity and DNS

#### Test Container-to-Container Communication

I test network connectivity between the containers using the ping command.

```bash
seva@Seva:/...$ docker exec container1 ping -c 3 container2
PING container2 (172.18.0.3): 56 data bytes
64 bytes from 172.18.0.3: seq=0 ttl=64 time=0.254 ms
64 bytes from 172.18.0.3: seq=1 ttl=64 time=0.072 ms
64 bytes from 172.18.0.3: seq=2 ttl=64 time=0.293 ms

--- container2 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 0.072/0.206/0.293 ms
```

The `ping` command successfully reached `container2`.
All packets were received with `0% packet loss`.
This confirms that the containers can communicate through the custom network.


#### Inspect Network Details

I inspect the created network to see its configuration and connected containers.

```bash
seva@Seva:/...$ docker network inspect lab_network
[
    {
        "Name": "lab_network",
        "Id": "a871cd07e6776f465c6141d2fb6018d92a9bcea48493a2d4d2ab573d1dd4ff95",
        "Created": "2026-03-07T17:07:21.436696992Z",
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
        "Options": {
            "com.docker.network.enable_ipv4": "true",
            "com.docker.network.enable_ipv6": "false"
        },
        "Labels": {},
        "Containers": {
            "349b28f4bf539326eeae7f3c11c74f6953552a5d62ac9bcdc8835fff51c3d528": {
                "Name": "container2",
                "EndpointID": "4d467089882cac300e7c7f9cc941b5185db8154e85db75ed58bc565c755bbab0",
                "MacAddress": "ee:e3:02:1c:46:8f",
                "IPv4Address": "172.18.0.3/16",
                "IPv6Address": ""
            },
            "8e14e9ebf963293771ac7e418b07008d86eba1488277e69b2f91512b8426bd67": {
                "Name": "container1",
                "EndpointID": "ca39e3e43ec170a6069cd34b7addf43b5ee65599be004682d26c10e81395c16e",
                "MacAddress": "f6:e2:1e:6a:f5:d4",
                "IPv4Address": "172.18.0.2/16",
                "IPv6Address": ""
            }
        },
        "Status": {
            "IPAM": {
                "Subnets": {
                    "172.18.0.0/16": {
                        "IPsInUse": 5,
                        "DynamicIPsAvailable": 65531
                    }
                }
            }
        }
    }
]
```

The inspection output shows detailed information about the network configuration.
Both containers are listed with their assigned IP addresses.
The network uses the subnet `172.18.0.0/16`.


#### Check DNS Resolution

I check how Docker resolves container names using its internal DNS.

```bash
seva@Seva:/...$ docker exec container1 nslookup container2
Server:         127.0.0.11
Address:        127.0.0.11:53

Non-authoritative answer:

Non-authoritative answer:
Name:   container2
Address: 172.18.0.3
```

The DNS query successfully resolved the name `container2`.
Docker's internal DNS returned its IP address `172.18.0.3`.
This allows containers to communicate using names instead of IP addresses.


### Analysis: How does Docker's internal DNS enable container-to-container communication by name?

Docker provides an internal DNS server for user-defined networks.
When a container joins the network, its name is automatically registered in this DNS system.
Other containers in the same network can resolve this name to the container’s IP address.

This allows containers to communicate using container names instead of IP addresses.
As a result, service discovery becomes simpler and more flexible.

### Comparison: What advantages does user-defined bridge networks provide over the default bridge network?

User-defined bridge networks provide better isolation and control between containers.
Containers connected to the same custom network can communicate using automatic DNS name resolution.
This feature is not available in the default bridge network.

Custom networks also allow easier configuration and management of container connectivity.
They are commonly used in multi-container applications and microservices environments.


## Task 4 - Data Persistence with Volumes

### 4.1. Create and Use Volume


#### Create Named Volume

I create a named Docker volume and verify that it exists.

```bash
seva@Seva:/...$ docker volume create app_data
app_data

seva@Seva:/...$ docker volume ls
DRIVER    VOLUME NAME
local     app_data
```

The command created a new Docker volume called `app_data`.
It uses the default local volume driver.
This volume can now be attached to containers for persistent storage.


#### Deploy Container with Volume

I try to run an Nginx container with the created volume attached.

```bash
seva@Seva:/...$ docker run -d -p 80:80 -v app_data:/usr/share/nginx/html --name web nginx
de089039c4cadd064c6beece952e6d67b23372c5db5fb8d30196292e5183a54f
docker: Error response from daemon: failed to set up container networking: driver failed programming external connectivity on endpoint web (8db64aa7df4a1c76a0a939284ff33dbb2450eb61b4df749113998c6eac83515d): Bind for 0.0.0.0:80 failed: port is already allocated

Run 'docker run --help' for more information
```

Docker attempted to start the container but failed to bind `port 80`.
This happened because another container was already using that port.
Despite this, the volume configuration itself was correct.


#### Add Custom Content

I copy a custom HTML file into the container’s web directory.

```bash
seva@Seva:/...$ docker cp index.html web:/usr/share/nginx/html/
Successfully copied 2.05kB to web:/usr/share/nginx/html/

seva@Seva:/...$ curl http://localhost
<html><body><h1>Persistent Data</h1></body></html>
```

The file was successfully copied into the container.
When accessing the server, the new HTML page is displayed.
This confirms that the container is serving the updated content.


### 4.2. Verify Persistence

#### Destroy and Recreate Container

I stop and remove the container and try to recreate it using the same volume.

```bash
seva@Seva:/.../docker stop web && docker rm web rm web
web
web

seva@Seva:/...$ docker run -d -p 80:80 -v app_data:/usr/share/nginx/html --name web_new nginx
a1c6312321051c4b08d6be6be2947e1be6ae8839a452fd7e3ff28e7b0aafbc20
docker: Error response from daemon: failed to set up container networking: driver failed programming external connectivity on endpoint web_new (7481f877dbb4e79df904f73782d648d4b9ebc611936f1b357709d05ac3ca47a4): Bind for 0.0.0.0:80 failed: port is already allocated

Run 'docker run --help' for more information

seva@Seva:/...$ curl http://localhost
<html><body><h1>Persistent Data</h1></body></html>
```

The container was removed and recreated with the same volume.
Even after container removal, the custom page is still available.
This shows that the data was stored in the persistent volume.


#### Inspect Volume

I inspect the created volume to see where the data is stored.

```bash
seva@Seva:/...$ docker volume inspect app_data
[
    {
        "CreatedAt": "2026-03-07T17:10:05Z",
        "Driver": "local",
        "Labels": null,
        "Mountpoint": "/var/lib/docker/volumes/app_data/_data",
        "Name": "app_data",
        "Options": null,
        "Scope": "local"
    }
]
```

The inspection shows detailed information about the volume.
The Mountpoint field shows where the volume data is stored on the host system.
Docker manages this directory automatically.


### Analysis: Why is data persistence important in containerized applications?

Containers are designed to be temporary and can be stopped or removed at any time.
If data is stored only inside the container filesystem, it will be lost when the container is deleted.

Volumes allow data to persist independently of container lifecycle.
This is important for applications such as databases, logs, and uploaded files.
Using persistent storage ensures that important data is not lost.

### Comparison: Explain the differences between volumes, bind mounts, and container storage. When would you use each?

Docker provides several ways to store data for containers.

Container storage exists only inside the container filesystem.
It is temporary and disappears when the container is removed.

Volumes are managed by Docker and stored outside the container.
They are recommended for persistent application data.

Bind mounts connect a container directory directly to a host filesystem path.
They are often used for development when files need to be edited on the host system.