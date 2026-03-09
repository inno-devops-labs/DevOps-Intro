# Lab 6 — Submission

## Task 1 — Container Lifecycle & Image Management

### 1.1 Basic Container Operations

#### List all containers

Command:
```sh
docker ps -a
```

Output:

![6_img_1.png](screenshots%2F6_img_1.png)

Command:
```sh
docker pull ubuntu:latest
docker images ubuntu
```

Output:

![6_img_2.png](screenshots%2F6_img_2.png)

Command:
```sh
cat /etc/os-release
```

Output:

![6_img_3.png](screenshots%2F6_img_3.png)

Command:
```sh
ps aux
```

Output:

![6_img_4.png](screenshots%2F6_img_4.png)

### 1.2 Image Export and Dependency Analysis

Command:
```sh
docker save -o ubuntu_image.tar ubuntu:latest
ls -lh ubuntu_image.tar
```

Output:

![6_img_5.png](screenshots%2F6_img_5.png)

Command:
```sh
docker rmi ubuntu:latest
```

Output:

![6_img_6.png](screenshots%2F6_img_6.png)


Command:
```sh
docker rm ubuntu_container
docker rmi ubuntu:latest
```

Output:

![6_img_7.png](screenshots%2F6_img_7.png)

### Analysis

Docker does not allow removing an image if a container created from this image still exists.
The container depends on the image as its base layer, so the image cannot be removed until the container is deleted.

The `docker save` command exports the image layers and metadata into a tar archive.
This archive can later be restored using `docker load`.

The tar archive size is similar to the image size because it contains all image layers.


## Task 2 — Custom Image Creation & Analysis

### 2.1
Command:
```sh
docker run -d -p 80:80 --name nginx_container nginx
curl http://localhost
```

Output:

![6_img_8.png](screenshots%2F6_img_8.png)

Command:
```sh
docker cp index.html nginx_container:/usr/share/nginx/html/
curl http://localhost
```

Output:

![6_img_9.png](screenshots%2F6_img_9.png)

### 2.2

Command:
```sh
docker commit nginx_container my_website:latest
docker images my_website
```

Output:
![6_img_10.png](screenshots%2F6_img_10.png)

Command:
```sh
docker rm -f nginx_container
docker run -d -p 80:80 --name my_website_container my_website:latest
curl http://localhost
```

Output:

![6_img_11.png](screenshots%2F6_img_11.png)

Command:
```sh
docker diff my_website_container
```

Output:

![6_img_12.png](screenshots%2F6_img_12.png)

### Analysis

The `docker diff` command shows filesystem changes inside the container.

Markers:
A – Added files
C – Changed files
D – Deleted files

The output shows that several nginx configuration and runtime files were modified or created during container execution.

Using `docker commit` allows saving container state into a new image quickly. However, this approach is not ideal for production because it does not provide reproducibility.

A better approach is using a Dockerfile, which allows building images in a reproducible and version-controlled way.


## Task 3 — Container Networking & Service Discovery

### 3.1
Command:
```sh
docker network create lab_network
docker network ls
```

Output:

![6_img_13.png](screenshots%2F6_img_13.png)

### 3.2

Command:
```sh
docker exec container1 ping -c 3 container2
```

Output:

![6_img_14.png](screenshots%2F6_img_14.png)

Command:
```sh
docker network inspect lab_network
```

Output:
![6_img_15.png](screenshots%2F6_img_15.png)
![6_img_16.png](screenshots%2F6_img_16.png)

Command:
```sh
docker exec container1 nslookup container2
```

Output:

![6_img_17.png](screenshots%2F6_img_17.png)

### Analysis

User-defined Docker networks provide automatic DNS resolution between containers.

In this task, both containers were connected to the same custom network `lab_network`.
Docker automatically created an internal DNS server (127.0.0.11) that resolves container names.

As a result, container1 was able to resolve the hostname `container2` to its IP address (172.19.0.3).

This makes communication between containers easier because services can be accessed by name instead of IP address.

Compared to the default bridge network, user-defined networks provide automatic DNS resolution and better container isolation.


## Task 4 — Data Persistence with Volumes

### 4.1
Command:
```sh
docker volume create app_data
docker volume ls
```

Output:

![6_img_18.png](screenshots%2F6_img_18.png)

Command:
```sh
docker cp index.html web:/usr/share/nginx/html/
curl http://localhost
```

Output:

![6_img_19.png](screenshots%2F6_img_19.png)

### 4.2
Command:
```sh
docker stop web && docker rm web
docker run -d -p 80:80 -v app_data:/usr/share/nginx/html --name web_new nginx
curl http://localhost
```

Output:

![6_img_20.png](screenshots%2F6_img_20.png)

Command:
```sh
docker volume inspect app_data
```

Output:

![6_img_21.png](screenshots%2F6_img_21.png)

### Analysis

Data persistence is important because containers are ephemeral and can be removed or recreated at any time.
If data is stored only inside the container filesystem, it is lost when the container is deleted.

Docker volumes provide persistent storage managed by Docker.
In this task, the `app_data` volume preserved the HTML file even after the original container was removed and a new one was created.

Comparison:
- Volumes are managed by Docker and are recommended for persistent application data.
- Bind mounts map a host directory into a container and are useful during development.
- Container storage is temporary and is removed together with the container.

Volumes are the best choice when data must survive container recreation.