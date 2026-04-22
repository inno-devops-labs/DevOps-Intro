## Задание 1
![alt text](image-19.png)

* на случай если будут проблемы со скриншотом:
 gorbu@Ksusha:/mnt/c/Users/gorbu/fdsfsdfds/DevOps-Intro/labs/lab12$ MODE=once go run main.go
{
  "moscow_time": "2026-04-22 13:43:05 MSK",
  "timestamp": 1776854585
}


* Объяснение работы единого файла main.go в трех контекстах:
Файл `main.go` динамически адаптируется под среду запуска:
1. **В режиме Spin (WAGI):** функция `isWagi()` проверяет наличие специфичных CGI-переменных окружения, после чего `runWagiOnce()` выводит ответ прямо в STDOUT

2. **В традиционном контейнере:** если специальных переменных нет, запускается стандартный HTTP-сервер (`net/http`)

3. **В CLI-режиме:** при переменной `MODE=once` программа просто выводит JSON с датой в консоль и завершается (это используется для замеров скорости)



## Задание 2

* **Binary size:** 4.5 MB
* **Image size:** 1.98 MB
* **Average startup time (5 runs):** 0.79 seconds
* **Memory usage:** 1.133 MiB

* скрин с сайта:
![alt text](image-20.png)

* ниже добавила выводы терминала в полном объёме:
gorbu@Ksusha:/mnt/c/Users/gorbu/fdsfsdfds/DevOps-Intro/labs/lab12$ ls -lh moscow-time-traditional
-rwxrwxrwx 1 gorbu gorbu 4.5M Apr 22 14:01 moscow-time-traditional

gorbu@Ksusha:/mnt/c/Users/gorbu/fdsfsdfds/DevOps-Intro/labs/lab12$ docker image inspect moscow-time-traditional --format '{{.Size}}' | awk '{print $1/1024/1024 " MB"}'
1.97717 MB

gorbu@Ksusha:/mnt/c/Users/gorbu/fdsfsdfds/DevOps-Intro/labs/lab12$ for i in {1..5}; do /usr/bin/time -f "%e" docker run --rm -e MODE=once moscow-time-traditional 2>&1 | tail -n 1; done | awk '{sum+=$1; count++} END {print "Average:", sum/count, "seconds"}'
Average: 0.79 seconds

gorbu@Ksusha:/mnt/c/Users/gorbu/fdsfsdfds/DevOps-Intro/labs/lab12$ docker run -d --rm --name test-traditional -p 8080:8080 moscow-time-traditional
49dcce8bf8ec8f2197e2679b9ce0e9dc34d9877e232f98f15f928488b179aa12
gorbu@Ksusha:/mnt/c/Users/gorbu/fdsfsdfds/DevOps-Intro/labs/lab12$ sleep 2
gorbu@Ksusha:/mnt/c/Users/gorbu/fdsfsdfds/DevOps-Intro/labs/lab12$ docker stats test-traditional --no-stream
CONTAINER ID   NAME               CPU %     MEM USAGE / LIMIT     MEM %     NET I/O         BLOCK I/O   PIDS
49dcce8bf8ec   test-traditional   0.00%     1.133MiB / 7.427GiB   0.01%     1.17kB / 126B   0B / 0B     5
gorbu@Ksusha:/mnt/c/Users/gorbu/fdsfsdfds/DevOps-Intro/labs/lab12$ docker stop test-traditional
test-traditional
gorbu@Ksusha:/mnt/c/Users/gorbu/fdsfsdfds/DevOps-Intro/labs/lab12$ 