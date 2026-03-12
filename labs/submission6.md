## Задание 1

Все последовательно выполненные команды:

gorbu@Ksusha:~$ docker ps -a
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
gorbu@Ksusha:~$ docker pull ubuntu:latest
latest: Pulling from library/ubuntu
01d7766a2e4a: Pull complete
fd8cda969ed2: Download complete
Digest: sha256:d1e2e92c075e5ca139d51a140fff46f84315c0fdce203eab2807c7e495eff4f9
Status: Downloaded newer image for ubuntu:latest
docker.io/library/ubuntu:latest
gorbu@Ksusha:~$ docker images ubuntu
                                                                                                    i Info →   U  In Use
IMAGE           ID             DISK USAGE   CONTENT SIZE   EXTRA
ubuntu:latest   d1e2e92c075e        119MB         31.7MB
gorbu@Ksusha:~$ docker run -it --name ubuntu_container ubuntu:latest
root@d452a1a85b53:/# cat /etc/os-release
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
root@d452a1a85b53:/# ps aux
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root         1  0.0  0.0   4588  3840 pts/0    Ss   13:19   0:00 /bin/bash
root        11  100  0.0   7888  3968 pts/0    R+   13:26   0:00 ps aux
root@d452a1a85b53:/# exit
exit
gorbu@Ksusha:~$ docker save -o ubuntu_image.tar ubuntu:latest
gorbu@Ksusha:~$ ls -lh ubuntu_image.tar
-rw------- 1 gorbu gorbu 31M Mar 10 16:28 ubuntu_image.tar
gorbu@Ksusha:~$ docker rmi ubuntu:latest
Error response from daemon: conflict: unable to delete ubuntu:latest (must be forced) - container d452a1a85b53 is using its referenced image d1e2e92c075e
gorbu@Ksusha:~$ docker rm ubuntu_container
ubuntu_container
gorbu@Ksusha:~$ docker rmi ubuntu:latest
Untagged: ubuntu:latest
Deleted: sha256:d1e2e92c075e5ca139d51a140fff46f84315c0fdce203eab2807c7e495eff4f9

**Результат docker ps -a**
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES

**Результат docker images**
IMAGE           ID             DISK USAGE   CONTENT SIZE   EXTRA
ubuntu:latest   d1e2e92c075e        119MB         31.7MB

**Размер образа и количество слоёв**

По выводу docker images ubuntu:

DISK USAGE: 119 MB

CONTENT SIZE: 31.7 MB

По выводу docker pull ubuntu:latest видно, что было загружено 2 слоя:

01d7766a2e4a

fd8cda969ed2

**Сравнение размера tar-файла с размером образа**

Размер tar-файла: 31 МБ

CONTENT SIZE образа: 31.7 МБ

DISK USAGE образа: 119 МБ

Размер tar-файла почти совпадает с CONTENT SIZE, потому что docker save сохраняет содержимое образа в виде слоёв и метаданных.
DISK USAGE больше, так как показывает фактическое место, которое занимает образ в локальном хранилище Docker с учётом внутренней структуры хранения.

**Сообщение об ошибке при первой попытке удаления**
Error response from daemon: conflict: unable to delete ubuntu:latest (must be forced) - container d452a1a85b53 is using its referenced image d1e2e92c075e

**Анализ: почему удаление образа не удаётся, если существует контейнер**

Удаление образа не выполняется, потому что контейнер связан с этим образом.
Контейнер создаётся на основе образа и использует его как базу своей файловой системы. Пока контейнер существует, Docker считает, что образ ещё нужен.

Даже если контейнер остановлен, он всё равно хранит ссылку на образ, из которого был создан. Поэтому Docker не разрешает удалить образ обычной командой docker rmi, чтобы не нарушить целостность зависимостей.
Сначала нужно удалить контейнер:docker rm ubuntu_container
И только после этого можно удалить сам образ:docker rmi ubuntu:latest

**Пояснение: что входит в экспортированный tar-архив**

В tar-архив, созданный командой docker save, входят: слои образа, метаданные образа, информация о тегах, конфигурация образа.
Этот архив позволяет перенести образ на другой компьютер и затем загрузить его обратно командой docker load.

docker save сохраняет именно образ, а не состояние работающего контейнера.
Изменения, сделанные внутри контейнера после запуска, в такой архив не попадают, если контейнер не был сохранён отдельно в новый образ.

## Задание 2

**Скриншот или вывод оригинальной приветственной страницы Nginx**

PS C:\Users\gorbu> curl.exe http://localhost:8080
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


**Пользовательский HTML-контент и проверка с помощью curl.**

 C:\Users\gorbu> curl.exe http://localhost:8080
﻿<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Мой сайт</title>
</head>
<body>
    <h1>Привет! Это мой сайт</h1>
    <p>Пользовательская страница для задания Docker.</p>
</body>
</html>


**Результатdocker diff my_website_container**

PS C:\Users\gorbu> docker diff nginx_container
C /etc
C /etc/nginx
C /etc/nginx/conf.d
C /etc/nginx/conf.d/default.conf
C /run
A /run/nginx.pid
C /usr
C /usr/share
C /usr/share/nginx
C /usr/share/nginx/html
C /usr/share/nginx/html/index.html
C /var
C /var/cache
C /var/cache/nginx
A /var/cache/nginx/client_temp
A /var/cache/nginx/fastcgi_temp
A /var/cache/nginx/proxy_temp
A /var/cache/nginx/scgi_temp
A /var/cache/nginx/uwsgi_temp

**Анализ: Объясните разницу в результатах (A=Добавлено, C=Изменено, D=Удалено).**

C /usr/share/nginx/html/index.html
Это основной результат работы. Он показывает, что файл стартовой страницы Nginx был изменён. Именно поэтому при обращении через curl отображается не стандартная страница, а пользовательская.

A /run/nginx.pid
Этот файл был создан при запуске процесса Nginx внутри контейнера. Это нормальное поведение работающего веб-сервера.

A /var/cache/nginx/client_temp,
A /var/cache/nginx/fastcgi_temp,
A /var/cache/nginx/proxy_temp,
A /var/cache/nginx/scgi_temp,
A /var/cache/nginx/uwsgi_temp
Эти каталоги были созданы самим Nginx во время работы для временных файлов и кэша.

C /etc/nginx/conf.d/default.conf
Изменение конфигурационного файла связано с внутренней настройкой контейнера Nginx при запуске. Это стандартное служебное изменение и не является основной частью пользовательской кастомизации.

- Общий вывод по анализу

Изменения в docker diff делятся на две группы:

Пользовательские изменения — замена файла /usr/share/nginx/html/index.html.

Служебные изменения — файлы и каталоги, созданные или изменённые самим Nginx в процессе запуска и работы.

**Размышления: Каковы преимущества и недостатки использования docker commitDockerfile при создании образов?**

docker commit удобен, когда нужно быстро сохранить текущее состояние контейнера в новый образ. Его плюс в простоте и скорости, особенно для тестов и учебных задач. Минусы в том, что такой способ плохо подходит для повторного использования: шаги сборки не записаны, изменения вносились вручную, поэтому образ сложнее поддерживать и воспроизводить.

Dockerfile удобен тем, что весь процесс создания образа описан в виде команд. Его плюсы — прозрачность, воспроизводимость, удобство хранения в системе контроля версий и использование в автоматической сборке. Минус в том, что его нужно заранее писать, и для простых одноразовых задач это может быть дольше.

Вывод: для быстрых экспериментов подходит docker commit, а для правильного и профессионального создания образов лучше использовать Dockerfile.

## Задание 3

**Результат выполнения команды ping, подтверждающий успешное подключение**

PS C:\Users\gorbu> docker exec container1 ping -c 3 container2
PING container2 (172.18.0.3): 56 data bytes
64 bytes from 172.18.0.3: seq=0 ttl=64 time=0.302 ms
64 bytes from 172.18.0.3: seq=1 ttl=64 time=0.212 ms
64 bytes from 172.18.0.3: seq=2 ttl=64 time=0.195 ms

--- container2 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 0.195/0.236/0.302 ms

**Результаты проверки сети, отображающие IP-адреса обоих контейнеров**
container2: 172.18.0.3
container1 (контейнеры находятся в одной подсети Docker): 172.18.0.x

**вывод разрешения DNS**

PS C:\Users\gorbu> docker exec container1 nslookup container2
Server:         127.0.0.11
Address:        127.0.0.11:53

Non-authoritative answer:
Name:   container2
Address: 172.18.0.3

Non-authoritative answer:

**Анализ: Каким образом внутренняя DNS-система Docker обеспечивает обмен данными между контейнерами по имени?**

В пользовательской bridge-сети Docker автоматически запускает встроенную DNS-службу.
Когда container1 обращается к имени container2, запрос отправляется на внутренний DNS-сервер Docker по адресу 127.0.0.11. Этот сервер находит контейнер с таким именем в той же сети и возвращает его внутренний IP-адрес.

Благодаря этому контейнеры могут взаимодействовать друг с другом по имени, а не по IP-адресу. Это удобно, потому что IP-адреса могут меняться, а имена контейнеров остаются понятными и постоянными в пределах сети.

**Сравнение: Какие преимущества предоставляют определяемые пользователем мостовые сети по сравнению со стандартной мостовой сетью?**

Пользовательские мостовые сети удобнее стандартной сети bridge, потому что:
контейнеры в такой сети автоматически находят друг друга по имени; 
есть встроенное DNS-разрешение;
проще организовать взаимодействие только нужных контейнеров;
сеть становится более изолированной и управляемой;
удобнее администрировать многоконтейнерные приложения.

Стандартная сеть bridge таких возможностей по именам контейнеров по умолчанию не даёт или делает это менее удобно.
Поэтому пользовательская мостовая сеть лучше подходит для лабораторных работ, тестирования и развертывания связанных сервисов.

## Задание 4

**Используется пользовательский HTML-контент**

 C:\Users\gorbu> Get-Content .\index.html
<html>
  <body>
    <h1>Persistent Data</h1>
  </body>
</html>

**Результат выполнения команды curl, показывающий, что содержимое сохраняется после пересоздания контейнера, сохраняется**

PS C:\Users\gorbu> docker rm web
web
PS C:\Users\gorbu> docker run -d -p 8081:80 -v app_data:/usr/share/nginx/html --name web_new nginx
164e7a2105f63e6d0a02d6901af5edbef723b880cead3f3a173035249f571b5e
PS C:\Users\gorbu> curl.exe http://localhost:8081
  <html>
  <body>
    <h1>Persistent Data</h1>
  </body>
</html>

**Результаты проверки объема с указанием точки крепления**

 C:\Users\gorbu> docker volume inspect app_data
[
    {
        "CreatedAt": "2026-03-12T17:57:35Z",
        "Driver": "local",
        "Labels": null,
        "Mountpoint": "/var/lib/docker/volumes/app_data/_data",
        "Name": "app_data",
        "Options": null,
        "Scope": "local"
    }
]

**Анализ: Почему сохранение данных важно в контейнеризированных приложениях?**

Сохранение данных важно, потому что контейнеры могут быть удалены и созданы заново. Без томов пользовательские файлы, настройки и данные приложения теряются. Том позволяет хранить данные отдельно от контейнера и использовать их повторно.

**Сравнение: Объясните различия между томами, привязкой данных и контейнерным хранилищем. Когда следует использовать каждый из них?**

Тома удобны для постоянного хранения данных Docker-приложений. Они управляются Docker и подходят для баз данных, сайтов и сервисов.
Bind mount связывает контейнер с конкретной папкой на хосте. Это удобно в разработке, когда нужно сразу видеть изменения файлов.
Контейнерное хранилище существует только внутри контейнера и удаляется вместе с ним. Оно подходит только для временных данных.

Вывод: для постоянного хранения лучше использовать тома, для разработки — bind mount, для временных данных — обычное хранилище контейнера.