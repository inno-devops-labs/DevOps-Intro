# Lab 6 Submission

## Task 1 — Container Lifecycle & Image Management

### Вывод команды `docker ps -a`:
```text
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
```
### Вывод команды `docker images`:
```text
REPOSITORY   TAG       IMAGE ID       CREATED       SIZE
ubuntu       latest    bbdabce66f1b   3 weeks ago   78.1MB
```

### Детали образа:
- Размер образа: 78.1MB
- Размер tar-файла: 77MB

### Сообщение об ошибке при первой попытке удаления:
```text
Error response from daemon: conflict: unable to remove repository reference "ubuntu:latest" (must force) - container 28e05cb12c97 is using its referenced image bbdabce66f1b
```

### Анализ:
- **Почему не удается удалить образ, если существует контейнер?** Удаление образа завершается ошибкой, потому что контейнер физически зависит от слоев файловой системы этого образа. Docker блокирует удаление, чтобы не нарушить целостность существующего контейнера.
- **Что содержится в экспортированном tar-файле?** Экспортированный tar-архив содержит все слои файловой системы образа в виде отдельных архивов, а также JSON-файл с метаданными.

---

## Task 2 — Custom Image Creation & Analysis

### HTML-контент и проверка через curl:
```text
Successfully copied 2.05kB to nginx_container:/usr/share/nginx/html/
<html><head><title>The best</title></head><body><h1>website</h1></body></html>
```

### Вывод команды `docker diff my_website_container`:
```text
C /etc
C /etc/nginx
C /etc/nginx/conf.d
C /etc/nginx/conf.d/default.conf
C /run
C /run/nginx.pid
```

### Анализ:
- **Объясняем вывод diff:** Вывод показывает изменения в доступном для записи слое контейнера по сравнению с базовым образом.
  * `C` (Changed) — означает, что файл был изменен.
- **Преимущества и недостатки docker commit по сравнению с Dockerfile:** 
  * Преимущества: Быстро и просто для разового тестирования или создания снимка состояния, не требует написания кода.
  * Недостатки: Процесс абсолютно непрозрачен, т.е. невозможно узнать, какие команды привели к текущему состоянию. Сложно воспроизвести заново. Dockerfile всегда предпочтительнее для реальной работы, так как это документированный, читаемый и автоматизированный рецепт.

---

## Task 3 — Container Networking & Service Discovery

### Вывод команды ping:
```text
PING container2 (172.18.0.3): 56 data bytes
64 bytes from 172.18.0.3: seq=0 ttl=64 time=1.977 ms
64 bytes from 172.18.0.3: seq=1 ttl=64 time=0.091 ms
64 bytes from 172.18.0.3: seq=2 ttl=64 time=0.071 ms

--- container2 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 0.071/0.713/1.977 ms
```

### Вывод проверки сети (IP-адреса):
```text
...
"Containers": {
            "4e9020825511b239825a5fa33d2291580ad2b9f6690e00def3f629c7d27314f4": {
                "Name": "container2",
                "EndpointID": "fe0b6170e33937141c7e001bf441a6dad667310435443c2fe4f23e5d2562474c",
                "MacAddress": "6e:b2:1a:66:6f:ad",
                "IPv4Address": "172.18.0.3/16",
                "IPv6Address": ""
            },
            "ae4216f4cd3f6ebaf87df8a4f65c2e0c2cbb47bdbe1d4008d570f9679c21a3f4": {
                "Name": "container1",
                "EndpointID": "b05b6babf1f47c218e21af1b6c0231079234a6f44089bb4187f65f5531ca9d86",
                "MacAddress": "de:05:1d:bc:35:1b",
                "IPv4Address": "172.18.0.2/16",
                "IPv6Address": ""
            }
        }
...
```

### Вывод разрешения DNS:
```text
Server:  127.0.0.11
Address: 127.0.0.11:53

Non-authoritative answer:

Non-authoritative answer:
Name: container2
Address: 172.18.0.3
```

### Анализ:
- **Как внутренний DNS Docker обеспечивает связь между контейнерами по имени?** Во встроенных пользовательских сетях Docker запускает свой внутренний DNS-сервер. Когда один контейнер обращается к другому по имени, этот DNS-сервер автоматически переводит (резолвит) имя во внутренний IP-адрес нужного контейнера.
- **Преимущества пользовательских сетей `bridge` перед дефолтной:** Главное преимущество - это автоматическое разрешение имен (DNS-резолвинг). В дефолтной сети `bridge` контейнеры могут общаться только по IP-адресам, что неудобно, так как IP меняются при каждом пересоздании контейнера. Кроме того, пользовательские сети обеспечивают лучшую изоляцию.

---

## Task 4 — Data Persistence with Volumes

### Использованный кастомный HTML-контент
```text
'<html><body><h1>Persistent Data</h1></body></html>'
```

### Вывод curl, показывающий сохранение контента:
```text
web
web
16705554c8e11fff875cb1999dc0473b32b2615dd864c6daf8a14843da35bd12
curl: (56) Recv failure: Connection reset by peer
```

### Вывод проверки тома (volume inspect):
```text
[
    {
        "CreatedAt": "2026-03-08T02:28:26Z",
        "Driver": "local",
        "Labels": null,
        "Mountpoint": "/var/lib/docker/volumes/app_data/_data",
        "Name": "app_data",
        "Options": null,
        "Scope": "local"
    }
]
```

### Анализ:
- **Почему сохранение данных важно в контейнеризированных приложениях?** Контейнеры временны. Если контейнер удаляется или падает, все данные внутри его слоя стираются. Сохранение данных критически важно для баз данных, файлов пользователей и логов, чтобы эта информация пережила перезапуск или обновление самого контейнера.
- **Различия между томами (volumes), привязками (bind mounts) и хранилищем контейнера:**
  * `Volumes` (тома): Управляются самим Docker, хранятся в специальной системной директории хоста. Это самый безопасный и рекомендуемый способ.
  * `Bind mounts` (привязки): Привязывают конкретную папку с твоей ОС к папке в контейнере. Зависят от структуры папок твоей ОС.
  * `Container storage` (хранилище контейнера): Временный слой самого контейнера. Исчезает при удалении контейнера. Используется только для временных файлов.
