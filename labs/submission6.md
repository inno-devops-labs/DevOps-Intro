\# Лабораторная работа №6

\## Задание 1.



\*\*docker ps -a\*\* 
CONTAINER ID IMAGE COMMAND CREATED STATUS PORTS NAMES


\*\*docker pull ubuntu:latest\*\*
latest: Pulling from library/ubuntu

Digest: sha256:...

Status: Downloaded newer image for ubuntu:latest



\*\*docker run -it --name ubuntu\_container ubuntu:latest\*\* (внутри контейнера)
cat /etc/os-release

PRETTY\_NAME="Ubuntu 24.04.4 LTS"

NAME="Ubuntu"

VERSION\_ID="24.04"

VERSION="24.04.4 LTS (Noble Numbat)"

VERSION\_CODENAME=noble

ID=ubuntu

ID\_LIKE=debian

HOME\_URL="https://www.ubuntu.com/"

SUPPORT\_URL="https://help.ubuntu.com/"

BUG\_REPORT\_URL="https://bugs.launchpad.net/ubuntu/"

PRIVACY\_POLICY\_URL="https://www.ubuntu.com/legal/terms-and-policies/privacy-policy"

UBUNTU\_CODENAME=noble

LOGO=ubuntu-logo

ps aux
USER PID %CPU %MEM VSZ RSS TTY STAT START TIME COMMAND

root 1 0.4 0.0 4596 4104 pts/0 Ss 17:05 0:00 /bin/bash

root 10 0.0 0.0 7896 4096 pts/0 R+ 17:05 0:00 ps aux

exit


\*\*docker save -o ubuntu\_image.tar ubuntu:latest\*\*

\*\*ls -lh ubuntu\_image.tar\*\*
-rw------- 1 ilya docker 31M апр 9 20:07 ubuntu\_image.tar


\*\*docker rmi ubuntu:latest\*\* (первая попытка, пока есть контейнер)
Error response from daemon: conflict: unable to delete ubuntu:latest (must be forced) - container 5f8f45185a49 is using its referenced image 84e77dee7d1b


\*\*docker rm ubuntu\_container\*\*
ubuntu\_container


\*\*docker rmi ubuntu:latest\*\* (после удаления контейнера)
Untagged: ubuntu:latest

Deleted: sha256:84e77dee7d1bc93fb029a45e3c6cb9d8aa4831ccfcc7103d36e876938d28895b


\*\*Анализ:\*\*

\- Размер tar-файла образа ubuntu:latest – 31 МБ.

\- Количество слоёв образа: можно посмотреть через `docker history ubuntu:latest`.

\- Ошибка при первом удалении возникает, потому что образ используется существующим контейнером (даже остановленным). Docker не позволяет удалить образ, пока есть хотя бы один контейнер, созданный из него.

\- Экспортируемый tar-файл содержит все слои образа, конфигурацию и манифесты – это полный слепок образа.



\## Задание 2 



\*\*docker run -d -p 80:80 --name nginx\_container nginx\*\*
4ab731bb745fcfb4b3cfd9fdfa350019aa5f3b75346347bdcf2453eea41de7cf


\*\*curl http://localhost\*\* (стандартная страница Nginx)
<!DOCTYPE html><html> <head> <title>Welcome to nginx!</title> ... </html> ```

<html>

<head><title>Лучший</title></head>

<body>

<h1>сайт</h1>

</body>

</html>
docker cp index.html nginx\_container:/usr/share/nginx/html/
Successfully copied 2.05kB to nginx\_container:/usr/share/nginx/html/
curl http://localhost (после копирования)

<html>

<head><title>Лучший</title></head>

<body>

<h1>сайт</h1>

</body>

</html>

docker commit nginx\_container my\_website:latest
sha256:b04c1d2d01d9b97d9c81fc3c15223296a5339b8d8a8b4bda202461074377315b
docker images

IMAGE               ID             DISK USAGE   CONTENT SIZE   EXTRA

my\_website:latest   b04c1d2d01d9        237MB           63MB        

nginx:latest        7f0adca1fc6c        240MB         65.8MB    U   

docker rm -f nginx\_container
nginx\_container

docker run -d -p 80:80 --name my\_website\_container my\_website:latest
f94a74093899fc595c6ab4ae498654cf9ca49a1e066b2093f28c70228e62d9a2
curl http://localhost (проверка пользовательского образа)

<html>

<head><title>Лучший</title></head>

<body>

<h1>сайт</h1>

</body>

</html>

docker diff my\_website\_container

C /run

C /run/nginx.pid

C /etc

C /etc/nginx

C /etc/nginx/conf.d

C /etc/nginx/conf.d/default.conf

Анализ:



A – добавлен новый файл (в данном случае наш index.html не отобразился в diff, возможно, потому что изменения уже были закоммичены в образ).



C – изменены файлы (конфигурационные файлы Nginx, PID-файл).



D – удалённых файлов нет.



Преимущества docker commit: быстрота, возможность сохранить состояние работающего контейнера.



Недостатки: непрозрачность, сложность воспроизведения, риск включить временные данные. Dockerfile предпочтительнее для автоматизации.

Задание 3.
docker network create lab\_network

60488ac8261b0209867781bfcbee7745741cc52a0a3e7d69beb43596e8120100
docker network ls

NETWORK ID     NAME          DRIVER    SCOPE

d305564ac826   bridge        bridge    local

61a26a9e3a30   host          host      local

60488ac8261b   lab\_network   bridge    local

09a12ece3550   none          null      local
docker run -dit --network lab\_network --name container1 alpine ash
d13e4b9bd5263d8b1665d44f207fe6f4f619f00d4f4ec214e04eab4ca67d4a17
docker run -dit --network lab\_network --name container2 alpine ash
d81f92ef0e8f82e4076aabdd352b048c097df6bfada3f58ac8a91b758f9f90b7
docker exec container1 ping -c 3 container2

PING container2 (172.18.0.3): 56 data bytes

64 bytes from 172.18.0.3: seq=0 ttl=64 time=0.106 ms

64 bytes from 172.18.0.3: seq=1 ttl=64 time=0.146 ms

64 bytes from 172.18.0.3: seq=2 ttl=64 time=0.132 ms



\--- container2 ping statistics ---

3 packets transmitted, 3 packets received, 0% packet loss

round-trip min/avg/max = 0.106/0.128/0.146 ms
docker network inspect lab\_network (фрагмент с IP-адресами)
"Containers": {

&#x20;   "d13e4b9bd526...": {

&#x20;       "Name": "container1",

&#x20;       "IPv4Address": "172.18.0.2/16"

&#x20;   },

&#x20;   "d81f92ef0e8f...": {

&#x20;       "Name": "container2",

&#x20;       "IPv4Address": "172.18.0.3/16"

&#x20;   }

}
docker exec container1 nslookup container2
Server:		127.0.0.11

Address:	127.0.0.11:53



Non-authoritative answer:

Name:	container2

Address: 172.18.0.3
Анализ:



Внутренний DNS Docker (127.0.0.11) автоматически разрешает имена контейнеров в их IP-адреса внутри пользовательской сети.



Пользовательская мостовая сеть обеспечивает изоляцию, автоматическое обнаружение сервисов и более безопасную среду по сравнению с сетью bridge по умолчанию.

Задание 4
docker volume create app\_data
app\_data
docker volume ls
DRIVER    VOLUME NAME

local     app\_data
docker run -d -p 80:80 -v app\_data:/usr/share/nginx/html --name web nginx (первая попытка – порт занят)
docker: Error response from daemon: Bind for 0.0.0.0:80 failed: port is already allocated
Остановка и удаление контейнера, занимающего порт 80
sudo docker stop my\_website\_container

sudo docker rm my\_website\_container
docker run -d -p 80:80 -v app\_data:/usr/share/nginx/html --name web nginx (успешно)
07e901702a602779937972477247917cee629270cfb791fca1183c26ffc8ae2b
Создание index2.html
<html>

<body>

<h1>Постоянные данные</h1>

</body>

</html>

docker cp index2.html web:/usr/share/nginx/html/index.html
Successfully copied 2.05kB to web:/usr/share/nginx/html/index.html
curl http://localhost

<html>

<body>

<h1>Постоянные данные</h1>

</body>

</html>

docker stop web \&\& docker rm web
web

web

docker rm web\_new (удаление старого конфликтующего контейнера)
web\_new

docker run -d -p 80:80 -v app\_data:/usr/share/nginx/html --name web\_new nginx
0a27e08b44cb19fdd7a838ab652df3c8d54793ec0d48c4262b6bb7ad45735bc2
curl http://localhost (после пересоздания контейнера)

<html>

<body>

<h1>Постоянные данные</h1>

</body>

</html>

docker volume inspect app\_data

\[

&#x20;   {

&#x20;       "CreatedAt": "2026-04-09T20:19:35+03:00",

&#x20;       "Driver": "local",

&#x20;       "Labels": null,

&#x20;       "Mountpoint": "/var/lib/docker/volumes/app\_data/\_data",

&#x20;       "Name": "app\_data",

&#x20;       "Options": null,

&#x20;       "Scope": "local"

&#x20;   }

]

Анализ:



Сохранение данных критически важно для баз данных, пользовательских файлов и логов, чтобы они не терялись при пересоздании контейнера.



Тома управляются Docker, хранятся в /var/lib/docker/volumes/, портабельны и безопасны.



Bind mounts привязывают конкретную директорию хоста – удобно для разработки.



Хранилище самого контейнера (слой чтения-записи) эфемерно и удаляется вместе с контейнером.



Использование томов рекомендуется для production, bind mounts – для активной разработки.



