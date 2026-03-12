# Task 1


### docker ps -a (before pull)
CONTAINER ID   IMAGE                                         COMMAND                  CREATED        STATUS                    PORTS     NAMES
92f1e87d46a1   cr.yandex/crpb0o5b6l9prfu6vvo6/ubuntu:hello   "/bin/bash"              8 months ago   Exited (0) 8 months ago             peaceful_payne
e6e2cb1c3a16   440dcf6a5640                                  "cr.yandex/crpb0o5b6…"   8 months ago   Created                             cranky_jackson
9b7314e7c667   postgres:15.3-alpine                          "docker-entrypoint.s…"   8 months ago   Exited (0) 8 months ago             chinook-postgre

### docker images ubuntu
REPOSITORY   TAG       IMAGE ID       CREATED       SIZE
ubuntu       latest    d1e2e92c075e   4 weeks ago   117MB

### Container exploration
- OS: Ubuntu 24.04.4 LTS (Noble Numbat)
- Processes inside container: только /bin/bash и ps aux —
  контейнер изолирован и не видит процессы хоста


### Image info
- Image size: 117 MB
### Image layers
- Layer count: 6
- Реальных слоёв с данными: 1 (ADD file, 87.6MB)
- Остальные 5 слоёв — метаданные (CMD, LABEL, ARG),
  они не занимают место на диске (SIZE = 0B)


### Tar file
- ubuntu_image.tar size: 29M
- Размер tar меньше образа, так как docker save
  сохраняет сжатые слои

### Error on first rmi attempt
Error response from daemon: conflict: unable to delete
ubuntu:latest (must be forced) - container 4bdad38d1684
is using its referenced image d1e2e92c075e


### Почему нельзя удалить образ пока существует контейнер?
Контейнер — это тонкий read-write слой поверх read-only
слоёв образа. Docker хранит жёсткую ссылку: контейнер
4bdad38d1684 ссылается на слои образа d1e2e92c075e.
Пока эта ссылка существует, удаление образа приведёт к
повреждению контейнера, поэтому Docker блокирует операцию.
После docker rm ubuntu_container ссылка исчезла и
docker rmi выполнился успешно.

### Что содержит экспортированный tar-файл?
docker save упаковывает:
- Все read-only слои образа (каждый слой — отдельный tar
  внутри архива)
- manifest.json — список слоёв и метаданные
- config.json — конфигурация образа, история команд,
  переменные окружения
Tar позволяет перенести образ на другую машину без
доступа к registry через docker load.

# Task 2

## 2.1 Deploy and Customize Nginx

### Original Nginx page (curl http://localhost)
<!DOCTYPE html>
<html>
<head><title>Welcome to nginx!</title></head>
<body><h1>Welcome to nginx!</h1>
...
</body>
</html>

### Custom index.html
<html>
<head><title>The best</title></head>
<body><h1>website</h1></body>
</html>

### After docker cp — curl http://localhost
<html>
<head><title>The best</title></head>
<body><h1>website</h1></body>
</html>

## 2.2 Custom Image

### docker images my_website
REPOSITORY   TAG       IMAGE ID       CREATED         SIZE
my_website   latest    f4e22b74f9c2   8 seconds ago   237MB

### curl after recreating from custom image
<html>
<head><title>The best</title></head>
<body><h1>website</h1></body>
</html>

### docker diff my_website_container
C /run
C /run/nginx.pid
C /etc
C /etc/nginx
C /etc/nginx/conf.d
C /etc/nginx/conf.d/default.conf

## Анализ docker diff

Вывод показывает только изменения ПОСЛЕ создания контейнера
из образа my_website:latest:
- C /run/nginx.pid — nginx создал файл с ID процесса при старте
- C /etc/nginx/conf.d/default.conf — nginx обновил конфиг при запуске

index.html НЕ отображается в diff, потому что он уже был
запечён в образ через docker commit — diff сравнивает
контейнер с его образом, а не с оригинальным nginx.

## docker commit vs Dockerfile

**docker commit** — быстрый способ сохранить изменения из
работающего контейнера. Удобен для экспериментов, но создаёт
"чёрный ящик": непонятно какие именно команды были выполнены
внутри. Нельзя нормально хранить в git и воспроизвести
на другой машине.

**Dockerfile** — текстовый файл с пошаговыми инструкциями
сборки образа. Каждый шаг задокументирован, файл хранится
в git как обычный код, образ можно пересобрать в любой момент.
Именно этот подход используется в продакшне и CI/CD.

**Вывод:** docker commit подходит только для быстрых
экспериментов. В реальных проектах всегда используется
Dockerfile, так как он обеспечивает воспроизводимость,
прозрачность и удобство совместной работы.


# Task3


## 3.1 Создание сети и контейнеров

### docker network ls
NETWORK ID     NAME          DRIVER    SCOPE
26f0707bd9dd   lab_network   bridge    local
44806457ce4b   bridge        bridge    local
115bcaa2b449   host          host      local

## 3.2 Проверка связи

### ping container2 из container1
3 packets transmitted, 3 received, 0% packet loss
container1 (172.19.0.2) → container2 (172.19.0.3)

### docker network inspect — IP адреса
- container1: 172.19.0.2/16
- container2: 172.19.0.3/16
- Gateway: 172.19.0.1
- Subnet: 172.19.0.0/16

### nslookup container2
Server: 127.0.0.11
Name:   container2
Address: 172.19.0.3

## Анализ

### Как работает внутренний DNS Docker?
В каждой пользовательской сети Docker запускает
встроенный DNS-сервер на адресе 127.0.0.11. При старте
контейнера Docker автоматически регистрирует его имя
в этом сервере. Когда container1 обращается по имени
container2, запрос уходит на 127.0.0.11, который
возвращает IP 172.19.0.3. Это позволяет контейнерам
общаться по именам без знания IP-адресов.

### User-defined bridge vs Default bridge
Default bridge не поддерживает DNS — контейнеры
могут общаться только по IP-адресам, которые могут
меняться при перезапуске. User-defined bridge
автоматически регистрирует имена контейнеров в DNS,
обеспечивает изоляцию (контейнеры из разных сетей
не видят друг друга) и позволяет гибко управлять
сетевой топологией без перезапуска Docker.

# Task 4

## 4.1 Создание volume и контейнера

### docker volume ls
DRIVER    VOLUME NAME
local     app_data

### Custom index.html
<html><body><h1>Persistent Data</h1></body></html>

### curl после docker cp
<html><body><h1>Persistent Data</h1></body></html>

## 4.2 Проверка персистентности

### curl после удаления и пересоздания контейнера
<html><body><h1>Persistent Data</h1></body></html>

### docker volume inspect app_data
Mountpoint: /var/lib/docker/volumes/app_data/_data
Driver: local
Scope: local

## Анализ

### Почему персистентность важна?
Контейнеры по природе эфемерны — при удалении все данные
внутри теряются. Базы данных, конфиги, файлы пользователей
должны жить дольше контейнера. Volume хранит данные на хосте
независимо от жизненного цикла контейнера, что подтверждает
эксперимент: данные сохранились после docker rm web.

### Volumes vs Bind Mounts vs Container Storage

**Named Volume** — Docker сам управляет хранилищем.
Данные сохраняются после удаления контейнера, легко
переносятся. Используется для БД и продакшн-данных.

**Bind Mount** — монтируется конкретная папка с хоста.
Удобно при разработке для синхронизации кода между
хостом и контейнером, но зависит от структуры хоста.

**Container Storage** — данные хранятся внутри контейнера.
Теряются при удалении контейнера. Подходит только для
временных файлов в процессе работы.



