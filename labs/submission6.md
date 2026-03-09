# 1 Task

somepatt@DESKTOP-NG99BTO:~$ docker ps -a
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
somepatt@DESKTOP-NG99BTO:~$ docker pull ubuntu:latest
latest: Pulling from library/ubuntu
01d7766a2e4a: Pull complete
Digest: sha256:d1e2e92c075e5ca139d51a140fff46f84315c0fdce203eab2807c7e495eff4f9
Status: Downloaded newer image for ubuntu:latest
docker.io/library/ubuntu:latest
somepatt@DESKTOP-NG99BTO:~$ docker images ubuntu
REPOSITORY   TAG       IMAGE ID       CREATED       SIZE
ubuntu       latest    bbdabce66f1b   3 weeks ago   78.1MB
somepatt@DESKTOP-NG99BTO:~$ docker run -it --name ubuntu_container ubuntu:latest
root@c9db2b1e48cf:/# cat /etc/os-release
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
root@c9db2b1e48cf:/# ps aux
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root         1  0.2  0.0   4588  4056 pts/0    Ss   11:43   0:00 /bin/bash
root        10  0.0  0.0   7888  4044 pts/0    R+   11:43   0:00 ps aux
root@c9db2b1e48cf:/# exit
exit
somepatt@DESKTOP-NG99BTO:~$ docker save -o ubuntu_image.tar ubuntu:latest
somepatt@DESKTOP-NG99BTO:~$ ls -lh ubuntu_image.tar
-rw------- 1 somepatt somepatt 77M Mar  9 14:44 ubuntu_image.tar
somepatt@DESKTOP-NG99BTO:~$ docker rmi ubuntu:latest
Error response from daemon: conflict: unable to remove repository reference "ubuntu:latest" (must force) - container c9db2b1e48cf is using its referenced image bbdabce66f1b
somepatt@DESKTOP-NG99BTO:~$ docker rm ubuntu_container
ubuntu_container
somepatt@DESKTOP-NG99BTO:~$ docker rmi ubuntu:latest
Untagged: ubuntu:latest
Untagged: ubuntu@sha256:d1e2e92c075e5ca139d51a140fff46f84315c0fdce203eab2807c7e495eff4f9
Deleted: sha256:bbdabce66f1b7dde0c081a6b4536d837cd81dd322dd8c99edd68860baf3b2db3
Deleted: sha256:efafae78d70c98626c521c246827389128e7d7ea442db31bc433934647f0c791
somepatt@DESKTOP-NG99BTO:~$


Размер image: 78.1MB
Количество слоев: 1
Error response from daemon: conflict: unable to remove repository reference "ubuntu:latest" (must force) - container c9db2b1e48cf is using its referenced image bbdabce66f1b
Размер файла .tar: 77M
Перед удалением image нужно остановить контейнер, только после этого можно удалить image.
В файле .tar: слои image, JSON-конфиг image, manifest.json и теги/репозитории

# 2 Task

somepatt@DESKTOP-NG99BTO:~$ curl http://localhost
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

somepatt@DESKTOP-NG99BTO:~$ touch index.html
somepatt@DESKTOP-NG99BTO:~$ cat index.html
somepatt@DESKTOP-NG99BTO:~$ nano index.html
somepatt@DESKTOP-NG99BTO:~$ cat index.html
<html>
<head>
<title>The best</title>
</head>
<body>
<h1>website</h1>
</body>
</html>
somepatt@DESKTOP-NG99BTO:~$ docker cp index.html nginx_container:/usr/share/nginx/html/
Successfully copied 2.05kB to nginx_container:/usr/share/nginx/html/
somepatt@DESKTOP-NG99BTO:~$ curl http://localhost
<html>
<head>
<title>The best</title>
</head>
<body>
<h1>website</h1>
</body>
</html>

somepatt@DESKTOP-NG99BTO:~$ docker diff my_website_container
C /etc
C /etc/nginx
C /etc/nginx/conf.d
C /etc/nginx/conf.d/default.conf
C /run
C /run/nginx.pid

C: изменены существующие файлы/директории контейнера.
A: новые файлы/директории появились в writable layer.
D: файлы/директории удалены из writable layer.
В моем выводе только C: контейнер в основном меняет runtime-файлы Nginx.


Плюсы docker commit: 
быстро и удобно для экспериментов
Минусы:
плохо воспроизводимо, история изменений неявная

Плюсы Dockerfile:
полная воспроизводимость, удобно для CI/CD и командной работы
Минусы:
требует больше времени на описание шагов

# 3 Task

somepatt@DESKTOP-NG99BTO:~$ docker exec container1 ping -c 3 container2
PING container2 (172.18.0.3): 56 data bytes
64 bytes from 172.18.0.3: seq=0 ttl=64 time=0.610 ms
64 bytes from 172.18.0.3: seq=1 ttl=64 time=0.166 ms
64 bytes from 172.18.0.3: seq=2 ttl=64 time=0.263 ms

--- container2 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 0.166/0.346/0.610 ms

somepatt@DESKTOP-NG99BTO:~$ docker network inspect lab_network
[
    {
        "Name": "lab_network",
        "Id": "50da361855ec90bc253ee5e05f0bd793b7145fadae6bf0a907df7abb83fdbfd7",
        "Created": "2026-03-09T12:15:27.664841742Z",
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
            "b22d1ab8a08f5ed2bf176b463e84c11e9d1837fb71d25ceb451325b94a1be9b3": {
                "Name": "container1",
                "EndpointID": "3f42938646028a8ebae7574a4bf124a9a98133bbac8f60922f492a4a42415bcc",
                "MacAddress": "3a:08:12:51:fd:63",
                "IPv4Address": "172.18.0.2/16",
                "IPv6Address": ""
            },
            "f912b7f22e2fb145bc26e67568f99d53795a3c61cf4275b2e11c1e67a4bde530": {
                "Name": "container2",
                "EndpointID": "80cb1810c808276d8a8143fc3b98ac81c8af726a5c00b3000c4b044c9d4b1b27",
                "MacAddress": "c2:86:72:ee:7b:b5",
                "IPv4Address": "172.18.0.3/16",
                "IPv6Address": ""
            }
        },
        "Options": {},
        "Labels": {}
    }
]

somepatt@DESKTOP-NG99BTO:~$ docker exec container1 nslookup container2
Server:         127.0.0.11
Address:        127.0.0.11:53

Non-authoritative answer:
Name:   container2
Address: 172.18.0.3

Non-authoritative answer:


Docker в user-defined сети поднимает встроенный DNS (127.0.0.11).
Когда container1 обращается к имени container2, DNS возвращает IP контейнера в этой сети (172.18.0.3), поэтому контейнеры могут общаться по имени без ручного управления /etc/hosts.

Автоматическое DNS-разрешение по именам контейнеров (в default bridge обычно нет удобного name-to-name DNS).
Лучшая изоляция: контейнеры в lab_network отделены от контейнеров в других сетях.
Гибкость: можно подключать/отключать контейнеры к сети на лету.
Более предсказуемая конфигурация для сервисов и микросервисной архитектуры.

# 4 Task

somepatt@DESKTOP-NG99BTO:~$ docker run -d -p 80:80 -v app_data:/usr/share/nginx/html --name web nginx
55f898253ec8290d3fdb7fcdba032eec4eb2165ac6523de3d8497c5bc515cac9
somepatt@DESKTOP-NG99BTO:~$ touch index.html
somepatt@DESKTOP-NG99BTO:~$ nano index.html
somepatt@DESKTOP-NG99BTO:~$ docker cp index.html web:/usr/share/nginx/html/
Successfully copied 2.05kB to web:/usr/share/nginx/html/
somepatt@DESKTOP-NG99BTO:~$ curl http://localhost
<html><body><h1>Persistent Data</h1></body></html>
somepatt@DESKTOP-NG99BTO:~$ docker stop web && docker rm web
web
web
somepatt@DESKTOP-NG99BTO:~$ docker run -d -p 80:80 -v app_data:/usr/share/nginx/html --name web_new nginx
ae0471d77fa43b6a22fb2f7a15d08283bb913c3e7dae5a978f541d14e479b1ac
somepatt@DESKTOP-NG99BTO:~$ curl http://localhost
<html><body><h1>Persistent Data</h1></body></html>
somepatt@DESKTOP-NG99BTO:~$ docker volume inspect app_data
[
    {
        "CreatedAt": "2026-03-09T12:37:17Z",
        "Driver": "local",
        "Labels": null,
        "Mountpoint": "/var/lib/docker/volumes/app_data/_data",
        "Name": "app_data",
        "Options": null,
        "Scope": "local"
    }
]

Данные должны переживать пересоздание контейнеров, иначе при каждом docker rm теряются пользовательские файлы, state и результаты работы приложения.

Volumes: управляются Docker, удобны для продакшена и переноса между контейнерами, лучший выбор по умолчанию для постоянных данных.
Bind mounts: монтируют конкретную папку хоста, удобны в разработке, но сильнее зависят от структуры хоста и прав доступа.
Container storage: временное хранилище, удаляется вместе с контейнером; подходит только для временных файлов/кэша.
