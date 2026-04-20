3## Task 1.

#### Nix

```
georgiy@DESKTOP-QL0CRI2:/mnt/c/Users/Георгий/DevOps-Intro/labs/lab11/app$ readlink result

/nix/store/51fh8ygld87p6dkcvjxf0cnsqq6hbfhi-app-1.0
georgiy@DESKTOP-QL0CRI2:/mnt/c/Users/Георгий/DevOps-Intro/labs/lab11/app$ sha256sum result/bin/app

0332eafc08f95ac61cbdca39b4046acc7ae16b258ef0e5285186e95eda316976  result/bin/app

georgiy@DESKTOP-QL0CRI2:/mnt/c/Users/Георгий/DevOps-Intro/labs/lab11/app$ rm result

georgiy@DESKTOP-QL0CRI2:/mnt/c/Users/Георгий/DevOps-Intro/labs/lab11/app$ nix-build

/nix/store/51fh8ygld87p6dkcvjxf0cnsqq6hbfhi-app-1.0
georgiy@DESKTOP-QL0CRI2:/mnt/c/Users/Георгий/DevOps-Intro/labs/lab11/app$ readlink result

/nix/store/51fh8ygld87p6dkcvjxf0cnsqq6hbfhi-app-1.0
```

**Сборки Nix воспроизводимы, потому что:**
	Все зависимости имеют адресацию по содержимому 
	Сборки выполняются в изолированной среде 
	Одни и те же входные данные всегда дают идентичные выходные данные
#### Docker
```
georgiy@DESKTOP-QL0CRI2:/mnt/c/Users/Георгий/DevOps-Intro/labs/lab11/app$ docker images | grep test-app


test-app                  latest    8b6ba877aecd   4 days ago    1.25GB

georgiy@DESKTOP-QL0CRI2:/mnt/c/Users/Георгий/DevOps-Intro/labs/lab11/app$ docker images | grep test-app


test-app                  latest    05712571ae04   4 days ago    1.25GB
```

**Сборки Docker не воспроизводятся по следующим причинам:**
	Базовые образы могут меняться со временем 
	Процесс сборки не является полностью детерминированным

## Task 2. 

```
georgiy@DESKTOP-QL0CRI2:/mnt/c/Users/Георгий/DevOps-Intro/labs/lab11/app$ docker images | grep -E "nix-reproducible|traditional-app"
traditional-app           latest    10884065c937   10 seconds ago   3.26MB
nix-reproducible-app      latest    f35d9224bbe9   56 years ago     598MB
```
Почему образ Nix такой большой?
Приложение, использующее Nix-деривацию, включает в себя весь компилятор Go и другие зависимости времени сборки, поскольку Nix не может автоматически различать зависимости времени сборки и времени выполнения для статически скомпилированных бинарных файлов Go. В результате dockerTools.buildImage упаковывает все пакеты, на которые ссылается замыкание, включая go-1.26.1, bash, glibc и т.д.

```
georgiy@DESKTOP-QL0CRI2:/mnt/c/Users/Георгий/DevOps-Intro/labs/lab11/app$ docker history nix-reproducible-app:latest
IMAGE          CREATED   CREATED BY   SIZE      COMMENT
3c5f86e25c1b   N/A                    310MB
georgiy@DESKTOP-QL0CRI2:/mnt/c/Users/Георгий/DevOps-Intro/labs/lab11/app$ docker history traditional-app:latest
IMAGE          CREATED          CREATED BY                        SIZE      COMMENT
10884065c937   11 minutes ago   ENTRYPOINT ["/app"]               0B        buildkit.dockerfile.v0
<missing>      11 minutes ago   COPY /build/app /app # buildkit   2.02MB    buildkit.dockerfile.v0
```