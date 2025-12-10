**NOTE TO CHECKING STAFF**
I did not manage to finish task 3 on time (therefore disallowing myself from doing task 4)

## Task 1

CLI:
![alt text](image.png)

Browser:
![alt text](image-1.png)

The main.go utilizes environmental variables to deduce the preferred mode, falling back to HTTP mode. 

## Task 2

### Sizes
```sh
[RatPC|rightrat lab12] sudo docker create --name temp-traditional moscow-time-traditional
d158df4598235c7322fed9f6ddf0e4ea546df25c192d46e38bd69922d4cb78cf
[RatPC|rightrat lab12] sudo docker cp temp-traditional:/app/moscow-time ./moscow-time-traditional
Successfully copied 4.7MB to /home/rightrat/ratsonal/F25-DevOps-Intro/labs/lab12/moscow-time-traditional
[RatPC|rightrat lab12] sudo docker rm temp-traditional
temp-traditional
[RatPC|rightrat lab12] ls -lh moscow-time-traditional 
-rwxr-xr-x 1 root root 4,5M дек 10 23:21 moscow-time-traditional
```
So, 4.5MB


```sh
[RatPC|rightrat lab12] sudo docker images moscow-time-traditional
                                                                                                      i Info →   U  In Use
IMAGE                            ID             DISK USAGE   CONTENT SIZE   EXTRA
moscow-time-traditional:latest   64b4d21e4c51       6.82MB         2.07MB
```
...or not

```sh
[RatPC|rightrat lab12] sudo docker image inspect moscow-time-traditional --format '{{.Size}}' |     awk '{print $1/1024/1024 " MB"}'
1.97643 MB
```

### Startup times

```sh
[RatPC|rightrat lab12] for i in {1..5}; do     /usr/bin/time -f "%e" sudo docker run --rm -e MODE=once moscow-time-traditional 2>&1 | tail -n 1; done | awk '{sum+=$1; count++} END {print "Average:", sum/count, "seconds"}'
Average: 0.158 seconds
```

### Memory usage

```sh
[RatPC|rightrat ~] sudo docker stats test-traditional --no-stream
CONTAINER ID   NAME               CPU %     MEM USAGE / LIMIT     MEM %     NET I/O           BLOCK I/O   PIDS
ace2c0e22f70   test-traditional   0.01%     3.086MiB / 31.21GiB   0.01%     18.3kB / 6.04kB   0B / 0B     5
```

### Browser run

![alt text](image-2.png)


