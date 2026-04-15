## Task 1 — Сборка воспроизводимых артефактов с нуля

### Установка Nix

Я установила Nix с помощью установщика Determinate Systems:

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

После установки я подключила окружение Nix в текущей shell-сессии:

```bash
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
```

Проверка установки:

```bash
nix --version
nix run nixpkgs#hello
```

Вывод:

```bash
nix (Determinate Nix 3.17.3) 2.33.3
Hello, world!
```

### Исходный код приложения

Я создала простое Go-приложение в файле `labs/lab11/app/main.go`:

```go
package main

import (
    "fmt"
    "time"
)

func main() {
    fmt.Printf("Built with Nix at compile time\n")
    fmt.Printf("Running at: %s\n", time.Now().Format(time.RFC3339))
}
```

Затем я инициализировала Go-модуль:

```bash
go mod init app
```

### Nix-деривация

Для сборки я использовала следующий файл `default.nix`:

```nix
let
  pkgs = import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/nixos-25.05.tar.gz") {};
in
pkgs.buildGoModule {
  pname = "app";
  version = "1.0.0";
  src = ./.;
  vendorHash = null;
}
```

Эта деривация собирает Go-приложение в изолированном окружении Nix и использует зафиксированный источник `nixpkgs`.

### Результат сборки

Я собрала приложение командой:

```bash
nix-build
```

Сборка завершилась успешно и создала символическую ссылку `result`, указывающую на путь в Nix store:

```bash
/nix/store/a46w2ii5vxm7hsszn476sxjb24zj79gn-app-1.0.0
```

После этого я запустила собранный исполняемый файл:

```bash
./result/bin/app
```

Вывод программы:

```bash
Built with Nix at compile time
Running at: 2026-04-14T11:53:21+03:00
```

### Доказательство воспроизводимости

Сначала я получила путь, на который указывает `result`:

```bash
readlink result
```

Вывод:

```bash
/nix/store/a46w2ii5vxm7hsszn476sxjb24zj79gn-app-1.0.0
```

Затем я удалила только символическую ссылку `result` и повторно выполнила сборку:

```bash
rm result
nix-build
readlink result
```

Вывод:

```bash
/nix/store/a46w2ii5vxm7hsszn476sxjb24zj79gn-app-1.0.0
```

Путь в Nix store оказался одинаковым в обеих сборках, что показывает: при одинаковых входных данных Nix создаёт один и тот же результат.

Далее я посчитала SHA256-хэш бинарного файла:

```bash
sha256sum ./result/bin/app
```

Вывод:

```bash
34171ef70af8cc848dee57e8dc284fc2d088626c24d3217c0b6101576c6b421a  ./result/bin/app
```

Этот результат подтверждает, что собранный исполняемый файл детерминирован при одинаковом исходном коде и одинаковом наборе зависимостей.

### Почему эта сборка воспроизводима

Nix хранит результаты сборки в каталоге `/nix/store`, где путь зависит от входных данных сборки и графа зависимостей.

Файл `result`, создаваемый командой `nix-build`, является не самой сборкой, а символической ссылкой на соответствующий путь в Nix store.

Поэтому удаление `result` и повторный запуск `nix-build` не меняют сам артефакт, если исходный код и зависимости остались теми же.

В отличие от традиционных сборок, которые могут зависеть от состояния хост-системы, Nix использует только явно объявленные зависимости, что повышает воспроизводимость на разных машинах и в разное время.

### Формат пути в Nix store

Пример пути:

```text
/nix/store/a46w2ii5vxm7hsszn476sxjb24zj79gn-app-1.0.0
```

Он состоит из следующих частей:
- `/nix/store` — глобальный каталог Nix store.
- `a46w2ii5vxm7hsszn476sxjb24zj79gn` — хэш, связанный со входами сборки.
- `app-1.0.0` — читаемое имя пакета и его версия.

Таким образом, путь в Nix store сам отражает воспроизводимость: если входные данные меняются, меняется и хэш, а значит Nix создаёт другой путь.

## Task 2 — Воспроизводимые Docker-образы с помощью Nix

### Сборка Docker-образа через Nix

Для сборки Docker-образа я использовала `dockerTools.buildImage`, который позволяет собрать Docker-совместимый tarball как результат Nix-сборки. Такой tarball затем можно загрузить в локальный Docker через `docker load`.


Файл `docker.nix`:

```nix
let
  pkgs = import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/nixos-25.05.tar.gz") {};
  app = import ./default.nix;
in
pkgs.dockerTools.buildImage {
  name = "lab11-app";
  tag = "latest";
  copyToRoot = [ app ];
  config = {
    Cmd = [ "${app}/bin/app" ];
  };
}
```

В этом выражении:
- `app = import ./default.nix;` повторно использует приложение из Task 1;
- `copyToRoot = [ app ];` добавляет собранный пакет в файловую систему контейнера;
- `Cmd = [ "${app}/bin/app" ];` задаёт команду запуска контейнера.

### Сборка и запуск Nix-образа

Сначала я запустила сборку:

```bash
nix-build docker.nix
```

После успешной сборки Nix выдал результат:

```bash
/nix/store/m3miw5hwhkam33ic7q21q00xb6cd9rrj-docker-image-lab11-app.tar.gz
```

Проверка типа результата показала, что `result` является символической ссылкой на tarball Docker-образа:

```bash
file result
```

Вывод:

```bash
result: symbolic link to /nix/store/m3miw5hwhkam33ic7q21q00xb6cd9rrj-docker-image-lab11-app.tar.gz
```

Затем я загрузила образ в Docker:

```bash
docker load < result
```

Вывод:

```bash
Loaded image: lab11-app:latest
```

После этого я запустила контейнер:

```bash
docker run --rm lab11-app:latest
```

Вывод:

```bash
Built with Nix at compile time
Running at: 2026-04-14T11:00:25Z
```

Это подтверждает, что образ, собранный через Nix, корректно загружается и запускается в Docker. Загрузка tarball через `docker load` соответствует стандартному способу импорта образов из архива. 

### Сравнение с обычным Dockerfile

Для сравнения я также использовала обычный `Dockerfile`:

```dockerfile
FROM golang:1.22
WORKDIR /app
COPY main.go .
RUN go build -o app main.go
CMD ["/app/app"]
```

Сначала сборка не удалась из-за сетевой ошибки при обращении к Docker Hub:

```text
failed to resolve source metadata for docker.io/library/golang:1.22: net/http: TLS handshake timeout
```

После предварительной загрузки базового образа командами

```bash
docker pull hello-world
docker pull golang:1.22
```

традиционная сборка прошла успешно:

```bash
docker build -t test-app:1 .
docker build -t test-app:2 .
```

### Размеры и история слоёв

Список образов показал существенную разницу в размере:

```bash
docker images | grep -E "lab11-app|test-app"
```

Вывод:

```bash
test-app    2        fab5e84bfba1   2 hours ago   1.25GB
test-app    1        4c0b2ce15360   2 hours ago   1.25GB
lab11-app   latest   3852061f1d0b   56 years ago  14.8MB
```

Таким образом, Nix-образ оказался значительно меньше обычного Docker-образа: примерно 14.8 MB против 1.25 GB.

История слоёв Nix-образа:

```bash
docker history lab11-app:latest
```

Вывод:

```bash
IMAGE          CREATED   CREATED BY   SIZE      COMMENT
3852061f1d0b   N/A                    8.59MB
```

История слоёв обычного Docker-образа:

```bash
docker history test-app:1
```

Вывод показывает большое количество унаследованных слоёв от `golang:1.22`, включая системные пакеты, переменные окружения и шаги `WORKDIR`, `COPY`, `RUN go build`.

Это означает, что традиционный Docker-образ содержит не только само приложение, но и весь тяжёлый базовый стек сборочного окружения. Команда `docker history` как раз используется для просмотра структуры слоёв образа и их размеров. 

### Проверка воспроизводимости

Для проверки воспроизводимости tarball образа я выполнила:

```bash
sha256sum result
rm result
nix-build docker.nix
sha256sum result
```

Первый хэш:

```bash
36358895a0041612a99efa9481707d190222543a6fc70e7f3d3dc61a6836674c  result
```

После повторной сборки был получен другой хэш:

```bash
1cc42dc5c1e6c14b7e3addd432a82d5364f7ba1e8777c9cb6da2f82a3d964366  result
```

Затем я выполнила ещё одну команду:

```bash
rm result
nix-build docker.nix --option build-repeat 2
sha256sum result
```

Nix выдал предупреждение:

```bash
warning: unknown setting 'build-repeat'
```

После этого был получен тот же хэш:

```bash
1cc42dc5c1e6c14b7e3addd432a82d5364f7ba1e8777c9cb6da2f82a3d964366  result
```

### Анализ результата

Nix действительно позволяет собирать Docker-образы декларативно через `dockerTools.buildImage`, а результатом сборки является tarball, который можно загрузить через `docker load`. 

На моей машине Nix-образ оказался намного меньше традиционного Docker-образа: 14.8 MB против 1.25 GB. Это объясняется тем, что обычный образ наследует большой базовый образ `golang:1.22`, тогда как Nix-образ содержит только нужные артефакты приложения. 

Однако в моей первой и второй сборке SHA256 tarball различался, поэтому в текущем виде строгая воспроизводимость Docker-образа не была доказана полностью.

Наиболее вероятная причина состоит в том, что в `default.nix` использовалось `src = ./.;`, а это включает текущее содержимое рабочей директории в источник сборки. Если в каталоге появляются дополнительные файлы или symlink `result`, входные данные меняются, и Nix создаёт другой артефакт. Для более чистой воспроизводимой сборки исходники следует фильтровать, например через `pkgs.lib.cleanSource ./.;`. 

Несмотря на это, результат показывает главное практическое преимущество Nix: контейнер можно собрать из декларативного описания, получить компактный образ и прозрачно анализировать его как обычный артефакт сборки.