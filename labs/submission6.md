Lab 6 Submission
Task 1 — Container Lifecycle & Image Management
1.1: Basic Container Operations
docker ps -a output:
```
CONTAINER ID IMAGE COMMAND CREATED STATUS PORTS NAMES
```

docker pull ubuntu:latest:
```
latest: Pulling from library/ubuntu
Digest: sha256:d1e2e92c075e5ca139d51a140fff46f84315c0fdce203eab2807c7e495eff4f9
Status: Downloaded newer image for ubuntu:latest
docker.io/library/ubuntu:latest
```

Interactive container session:
```
root@fcce872b4224:/# cat /etc/os-release
PRETTY_NAME="Ubuntu 24.04.4 LTS"
NAME="Ubuntu"
VERSION_ID="24.04"
VERSION="24.04.4 LTS (Noble Numbat)"
VERSION_CODENAME=noble

root@fcce872b4224:/# ps aux
USER PID %CPU %MEM VSZ RSS TTY STAT START TIME COMMAND
root 1 0.1 0.0 4588 3800 pts/0 Ss 13:05 0:00 /bin/bash
root 10 0.0 0.0 7888 3752 pts/0 R+ 13:05 0:00 ps aux
```

1.2: Image Export and Dependency Analysis
Export image to tar:
```
docker save -o ubuntu_image.tar ubuntu:latest
```

Tar file size:
```
ls -lh ubuntu_image.tar
-rw-r--r-- 1 LevPe LevPe 29M Mar 12 16:06 ubuntu_image.tar
```

First removal attempt (fails):
```
docker rmi ubuntu:latest
Error response from daemon: conflict: unable to delete ubuntu:latest (must be forced) - container fcce872b4224 is using its referenced image d1e2e92c075e
```

Remove container and try again:
```
docker rm ubuntu_container
ubuntu_container

docker rmi ubuntu:latest
Untagged: ubuntu:latest
Deleted: sha256:d1e2e92c075e5ca139d51a140fff46f84315c0fdce203eab2807c7e495eff4f9
```

Analysis:

Image size: ```78MB

Tar file size: 29MB

Why does image removal fail when a container exists? The container references the image layers for its operation. Docker protects data integrity - deleting the image would make the container inoperable.

What is included in the exported tar file? All image layers, metadata, configuration, and manifest.

Task 2 — Custom Image Creation & Analysis
2.1: Deploy and Customize Nginx
Deploy Nginx container:
```
docker run -d -p 80:80 --name nginx_container nginx
32f331c8fa3eb8e33fcb0258741bce49e55b6527d84b70f0ed8e9b73799a1c63
```

Original Nginx welcome page:
```
curl http://localhost

<!DOCTYPE html><html> <head> <title>Welcome to nginx!</title> ... </html> ```
2.2: Create and Test Custom Image
Commit container to image:
```
docker commit nginx_container my_website:latest
sha256:81604511c06eaefd58931a56c7a01b3d5b0e3fb56174ae3a88e85c83787af1bd
```

Verify custom image:
```
docker images my_website
REPOSITORY TAG IMAGE ID CREATED SIZE
my_website latest 81604511c06e 2 seconds ago 237MB
```

Remove original container and deploy from custom image:
```
docker rm -f nginx_container
docker run -d -p 80:80 --name my_website_container my_website:latest
689658fb3d60fd74c81515c821e5f81df5d9e686a4124e1ddc64f0768102738b
```

Analyze filesystem changes:
```
docker diff my_website_container
C /run
C /run/nginx.pid
C /etc
C /etc/nginx
C /etc/nginx/conf.d
C /etc/nginx/conf.d/default.conf
```

Reflection: docker commit vs Dockerfile

docker commit advantages: Quick, good for debugging

Dockerfile advantages: Reproducible, versionable, documented

Task 3 — Container Networking & Service Discovery
3.1: Create Custom Network
Create bridge network:
```
docker network create lab_network
3d6cb2496393d178a7ce8d9db017e6590ada1bf203d6f621acc2af14d33cde32
```

Deploy connected containers:
```
docker run -dit --network lab_network --name container1 alpine ash
c545103a29166d5702d3606126b83e9af2aa51b288bb3621b5d695df1f3361dd

docker run -dit --network lab_network --name container2 alpine ash
696afedfebd6c1aab2dc6bf1bb96c1049b6a78ce08f69b64d3fe68056dfe26e7
```

3.2: Test Connectivity and DNS
Test container-to-container communication:
```
docker exec container1 ping -c 3 container2
PING container2 (172.18.0.3): 56 data bytes
64 bytes from 172.18.0.3: seq=0 ttl=64 time=0.092 ms
64 bytes from 172.18.0.3: seq=1 ttl=64 time=0.082 ms
64 bytes from 172.18.0.3: seq=2 ttl=64 time=0.268 ms
```

Network inspection:
```
docker network inspect lab_network
{
"Name": "lab_network",
"Driver": "bridge",
"Containers": {
"696afedfebd6...": {"Name": "container2", "IPv4Address": "172.18.0.3/16"},
"c545103a2916...": {"Name": "container1", "IPv4Address": "172.18.0.2/16"}
}
}
```

Analysis:

DNS in Docker: Automatic name resolution in user-defined networks

Advantages over default bridge: Automatic DNS, isolation, dynamic connectivity

Task 4 — Data Persistence with Volumes
4.1: Create and Use Volume
Create named volume:
```
docker volume create app_data
app_data
```

Deploy container with volume:
```
docker run -d -p 80:80 -v app_data:/usr/share/nginx/html --name web nginx
168dcec644a6a8a78dac6373877a6b3279d5acbbb9d777dc5872efe416aeac2e
```

Add custom content:
```
echo '<html><body><h1>Persistent Data</h1></body></html>' > index.html
docker cp index.html web:/usr/share/nginx/html/
Successfully copied 2.05kB to web:/usr/share/nginx/html/
```

Verify custom page:
```
curl http://localhost

<html><body><h1>Persistent Data</h1></body></html> ```
4.2: Verify Persistence
Destroy container:
```
docker stop web && docker rm web
web
web
```

Recreate container with same volume:
```
docker run -d -p 80:80 -v app_data:/usr/share/nginx/html --name web_new nginx
152ed55cb32cda478e7d43107a8d6b357eebf36d704cda2f5cb4ed21a998910d
```

Verify data persistence:
```
curl http://localhost

<html><body><h1>Persistent Data</h1></body></html> ```
Volume inspect:
```
docker volume inspect app_data
[
{
"CreatedAt": "2026-03-12T13:16:37Z",
"Driver": "local",
"Mountpoint": "/var/lib/docker/volumes/app_data/_data",
"Name": "app_data",
"Scope": "local"
}
]
```

Analysis:

Why is data persistence important? Containers are ephemeral; volumes allow data to survive container recreation

Storage types comparison:

Volumes: Docker-managed, production use

Bind mounts: Host paths, development

tmpfs: In-memory, temporary data