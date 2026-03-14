I.

1. C:\Users\Umion>docker ps -a
CONTAINER ID   IMAGE                    COMMAND           CREATED        STATUS                    PORTS     NAMES
37e32012f2e5   cinemabot-telegram-bot   "python bot.py"   9 months ago   Exited (0) 9 months ago             telegram_bot

C:\Users\Umion>docker images ubuntu
REPOSITORY   TAG       IMAGE ID       CREATED       SIZE
ubuntu       latest    bbdabce66f1b   4 weeks ago   78.1MB

2. 7 слоев и 78.1MB

3. Размер image: 78.1 MB. Размер .tar:  80 654 848 байт = 80МБ. 

4. C:\Users\Umion>docker rmi ubuntu:latest
Error response from daemon: conflict: unable to remove repository reference "ubuntu:latest" (must force) - container cafc415d1b72 is using its referenced image bbdabce66f1b

5. Образ и контейнер связаны отношением класс–объект
Образ - это неизменяемый шаблон, содержащий файловую систему и настройки.
Контейнер - это запущенный экземпляр образа, который добавляет поверх образа слой записи (container layer).
Docker защищает образы от удаления, если от них зависят существующие контейнеры. 

6. Команда docker save сохраняет полный образ со всей его историей и метаданными, включая:
Все слои файловой системы,
Манифест (manifest.json), описывающий слои и конфигурацию,
Файл конфигурации образа (<image_id>.json),
Репозиторий (repositories) - информацию о тегах.

II.

1. C:\Users\Umion>curl http://localhost
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

2. 
C:\Users\Umion>curl http://localhost
<html>
<head>
<title>The best</title>
</head>
<body>
<h1>website</h1>
</body>
</html>

3. C:\Users\Umion>docker diff my_website_container
C /run
C /run/nginx.pid
C /etc
C /etc/nginx
C /etc/nginx/conf.d
C /etc/nginx/conf.d/default.conf

4. Это системные изменения, мои действия не повлияли на вывод здесь файлов.

5. Dockerfile делает прозрачность и воспроизводимость сборки через код, тогда как docker commit создает черный ящик с системным мусором, который трудно поддерживать.
Как правило, docker commit используют в быстрых и не очень важных вещах, а dockerfile в продакшене

III.

1. C:\Users\Umion>docker exec container1 ping -c 3 container2
PING container2 (172.19.0.3): 56 data bytes
64 bytes from 172.19.0.3: seq=0 ttl=64 time=0.238 ms
64 bytes from 172.19.0.3: seq=1 ttl=64 time=0.090 ms
64 bytes from 172.19.0.3: seq=2 ttl=64 time=0.088 ms

2. [
    {
        "Name": "lab_network",
        "Id": "16a6f5b8793bf4117989d25baf2134f501d8fee02a787eb93003685ce8848e64",
        "Created": "2026-03-13T20:04:10.386322651Z",
        "Scope": "local",
        "Driver": "bridge",
        "EnableIPv4": true,
        "EnableIPv6": false,
        "IPAM": {
            "Driver": "default",
            "Options": {},
            "Config": [
                {
                    "Subnet": "172.19.0.0/16",
                    "Gateway": "172.19.0.1"
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
            "e77e20cac07f2b90658727c86b7394701c634600bdce043664b5be66c1c62389": {
                "Name": "container2",
                "EndpointID": "4c9aec20c560565e6305c1f87f3e61e2641568afb281c4292f1e9394eee85a1b",
                "MacAddress": "6e:0d:ff:04:8a:c8",
                "IPv4Address": "172.19.0.3/16",
                "IPv6Address": ""
            },
            "e9b3ca831ca0ec27358459590694f3e77d140396b9f3d6a460c1a344e0079eeb": {
                "Name": "container1",
                "EndpointID": "3d6d9af8d5dbef5ad4050a56eb78935fe794579ba9dc8d7a45da8942f4da91b5",
                "MacAddress": "22:03:78:f2:61:cc",
                "IPv4Address": "172.19.0.2/16",
                "IPv6Address": ""
            }
        },
        "Options": {},
        "Labels": {}
    }
]

3. C:\Users\Umion>docker exec container1 nslookup container2
Server:         127.0.0.11
Address:        127.0.0.11:53

Non-authoritative answer:

Non-authoritative answer:
Name:   container2
Address: 172.19.0.3

4. Встроенный в Docker резолвер запускает DNS-сервер по адресу 127.0.0.11 внутри каждого контейнера. Когда мы запускаем контейнер, его имя и IP-адрес автоматически регистрируются в базе данных Docker и когда container1 обращается к container2 по имени, запрос перехватывается резолвером, который возвращает актуальный IP-адрес из базы.

5. Насколько я понимаю, преимущество пользовательских сетей - автоматический DNS-резолвинг, позволяющий контейнерам в докере связываться по иманам, а не Ip адресам.

IV.

1. C:\Users\Umion>curl http://localhost:8080
<html><body><h1>Persistent Data</h1></body></html>

2. C:\Users\Umion>docker volume inspect app_data
[
    {
        "CreatedAt": "2026-03-14T09:16:23Z",
        "Driver": "local",
        "Labels": null,
        "Mountpoint": "/var/lib/docker/volumes/app_data/_data",
        "Name": "app_data",
        "Options": null,
        "Scope": "local"
    }
]

3. Дело в том, что контейнеры временны, а бывают данные, которые хочется хранить и после остановки и удаления контейнера. В продакшене системы обновляются по несколько раз в день, и каждое обновление приводило бы к удалению всех прошлых данных.

4. Содержимое контейнеров - это временное место хранения внутри самого контейнера, который существует, пока контейнер жив. Использовать для временных файлов, которые нужны только в рамках работы именно с этим контейнером.
Bind Mounts - это просто отображение из папки в контейнер, и я могу редактировать ее содержимое и оттуда, и оттуда, и везде все будет синхронизировано. Используется при разработке, когда нужно все редактировать в моменте.
Тома - специальные области, в которых хранятся файлы. Они нужны для бекапов и переноса данных между контейнерами.
