## Task 1.

```
docker ps -a
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES

docker images ubuntu
REPOSITORY   TAG       IMAGE ID       CREATED       SIZE
ubuntu       latest    d1e2e92c075e   4 weeks ago   117MB

root@a4231379eded:/# ps aux
USER         PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root           1  0.0  0.0   4588  3584 pts/0    Ss   13:01   0:00 /bin/bash
root          10  0.0  0.1   7888  3968 pts/0    R+   13:02   0:00 ps aux

ls ubuntu_image.tar
Каталог: C:\Users\Георгий
Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
-a----        12.03.2026     16:03       29745152 ubuntu_image.tar

docker rmi ubuntu:latest
Error response from daemon: conflict: unable to delete ubuntu:latest (must be forced) - container a4231379eded is using its referenced image d1e2e92c075e
```
Докер не дает удалить образ, так как контейнер от него зависит. Контейнер использует образ в качестве базового слоя файловой системы. Удаление образа приведет к поломке контейнера.

## Task 2.

![[lab6_1.png]]
C - изменено
A - добавлено
D - удалено
Делал со второй попытки, поэтому только изменения

```
docker diff my_website_container
C /etc
C /etc/nginx
C /etc/nginx/conf.d
C /etc/nginx/conf.d/default.conf
C /run
C /run/nginx.pid
```

docker commit - быстрый способ создания образов, невозможно воспроизвести результат,  нет контроля версий.
Dockerfile - обеспечивает воспроизводимые сборки и контроль версий.

## Task 3.

```
docker exec container1 ping -c 3 container2
PING container2 (172.18.0.3): 56 data bytes
64 bytes from 172.18.0.3: seq=0 ttl=64 time=1.374 ms
64 bytes from 172.18.0.3: seq=1 ttl=64 time=0.086 ms
64 bytes from 172.18.0.3: seq=2 ttl=64 time=0.173 ms

docker exec container1 nslookup container2
Server:         127.0.0.11
Address:        127.0.0.11:53

Non-authoritative answer:

Non-authoritative answer:
Name:   container2
Address: 172.18.0.3

"Containers": {
	"a1bab7011a46cace217e26296a84472767aeedd8725c00073c4161a2f0891344": {
		"Name": "container1",
		"EndpointID": "f69a4bdd81b2e2147a31bc68f5bd8afb371234d4c34a228ae4f83b677f0c2304",
		"MacAddress": "52:28:b8:af:c2:c6",
		"IPv4Address": "172.18.0.2/16",
		"IPv6Address": ""
	},
	"edd771d7d8546d7525829c52f7465dc276db77372aba50829e576824af2dc9d4": {
		"Name": "container2",
		"EndpointID": "5268a8c494579e9b8cb63956e0666dde02eb9053ac17220259691e415040e28f",
		"MacAddress": "fa:3f:61:a5:08:3d",
		"IPv4Address": "172.18.0.3/16",
		"IPv6Address": ""
```
Docker предоставляет DNS-сервер для пользовательских сетей.
Преимущества пользовательских мостовых сетей: 
- лучшая изоляция контейнеров 
- упрощенное обнаружение сервисов

## Task 4. 

![[lab6_2.png]]

Docker volumes позволяют хранить данные вне контейнера, поэтому данные сохраняются даже при повторном создании контейнера. 
**volumes** - хранятся во внутренних каталогах Docker.
**bind mounts** - связывание каталога хоста с каталогом контейнера.
**container storage** - внутренние хранилище контейнера, удаляется при удалении контейнера.