## Task 1.

![[12-1.png]]

Один и тот же файл main.go работает в трех режимах: 
- Режим командной строки (CLI) через MODE=once 
- HTTP-сервер (создание локального сайта) 
- Режим WAGI (WAGI) через определение REQUEST_METHOD

## Task 2.

![[12-2.png]]

```
georgiy@DESKTOP-QL0CRI2:/mnt/c/Users/Георгий/DevOps-Intro/labs/lab12$ docker stats test-traditional --no-stream

CONTAINER ID   NAME               CPU %     MEM USAGE / LIMIT    MEM %     NET I/O         BLOCK I/O   PIDS
96b048d87f66   test-traditional   0.00%     1.16MiB / 3.679GiB   0.03%     1.17kB / 126B   0B / 0B     5
```

```
REPOSITORY                TAG       IMAGE ID       CREATED         SIZE
moscow-time-traditional   latest    9fcc57c07c20   2 minutes ago   6.79MB


georgiy@DESKTOP-QL0CRI2:/mnt/c/Users/Георгий/DevOps-Intro/labs/lab12$ docker image inspect moscow-time-traditional --format '{{.Size}}' | \

awk '{print $1/1024/1024 " MB"}'
1.97717 MB


georgiy@DESKTOP-QL0CRI2:/mnt/c/Users/Георгий/DevOps-Intro/labs/lab12$ for i in {1..5}; do
    /usr/bin/time -f "%e" docker run --rm -e MODE=once moscow-time-traditional 2>&1 | tail -n 1
done | awk '{sum+=$1; count++} END {print "Average:", sum/count, "seconds"}'

Average: 0.388 seconds


georgiy@DESKTOP-QL0CRI2:/mnt/c/Users/Георгий/DevOps-Intro/labs/lab12$ docker run --rm --name test-traditional -p 8080:8080 moscow-time-traditional
2026/04/26 18:32:11 Server starting on :8080
```

	4.5 mb (moscow-time-traditional) - бинаарный
	docker images: 6.79 mb  - образ
	docker inspect: 1.98 mb - образ
	0.388с время запуска

	1.16mb - docker stats
