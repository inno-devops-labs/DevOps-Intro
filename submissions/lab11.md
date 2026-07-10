# Lab 11

Frolova AI - M25RO-01

a.frolova@innopolis.university

Ссылка на PR: https://github.com/inno-devops-labs/DevOps-Intro/pull/1414

## Task1

### 1.1 flake.nix

(Файл `flake.nix`)[https://github.com/kicchhi/DevOps-Intro/blob/feature/lab11/flake.nix]

- [x] - Привязка nixpkgs к определённой версии канала (nixos-25.11);
- [x] - Пакет quicknotes (и default), собирающий исходники из app/ (указано { src = ./app; ... });
- [x] - Используется pkgs.buildGoModule;
- [x] - env = { CGO_ENABLED = "0"; };
- [x] - Установлен vendorHash = null (у проекта нет внешних зависимостей, иначе будет ошибка);
- [x] - ldflags = [ "-s" "-w" ];
- [x] - Предоставлен devShell с go, gopls, golangci-lint.

```bash
{
  description = "QuickNotes - a small Go notes API";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        # Явно используем Go 1.24
        go = pkgs.go_1_24;
      in
      {
        packages.default = pkgs.buildGoModule {
          pname = "quicknotes";
          version = "0.1.0";

          src = ./app;

          vendorHash = null;
          subPackages = [ "." ];

          ldflags = [ "-s" "-w" ];

          env = {
    		CGO_ENABLED = "0";
  	  };

          meta = {
            description = "QuickNotes - a small Go notes API";
            license = pkgs.lib.licenses.mit;
          };
        };

        packages.quicknotes = self.packages.${system}.default;

        devShell = pkgs.mkShell {
          buildInputs = [
            go
            pkgs.gopls
            pkgs.golangci-lint
          ];
        };
      }
    );
}
```

flake.lock:

![alt text](image-2.png)

### 1.2 Проверка воспроизводимости

Два запуска `nix build` в разных терминалах дали один и тот же хеш, это доказывает воспроизводимость сборки в пределах одной машины.

![alt text](image.png)

Сборка в изолированном Docker-контейнере дала тот же хэш:

```bash
docker run --rm -it -v "D:/homework/DevOps-Intro:/repo" nixos/nix bash
cd /repo
nix --extra-experimental-features "nix-command flakes" build .#quicknotes
nix-store --query --hash $(readlink result)
```

Команда `nix build .#quicknotes` была модифицирована флагами.

![alt text](image-1.png)


Ваш flake.nix (вставьте; flake.lock можно связать)
nix build .#quicknotes выдержка из лога
Два nix-store --query --hash вывода из двух независимых сред — идентичны
./result/bin/quicknotes & + curl /health доказательство того, что он работает
Ответы на вопросы по дизайну от a до d

### Проверка бинарника

```bash
./result/bin/quicknotes &
sleep 2
curl http://localhost:8080/health
```

![alt text](image-3.png)

## Design questions

a) Why does `go build` not produce bit-identical outputs on two machines, even from the same Git SHA?

`go build` включает временные метки, пути к файлам и иногда случайные идентификаторы в бинарник. Также Go может решать зависимости по-разному, в зависимости от версии Go или сетевых условий при загрузке модулей.

---

b) `vendorHash` is a SHA over what, exactly? What happens if you set `vendorHash = null;`?

`vendorHash` — это хеш содержимого папки `vendor`, которая создаётся Nix при сборке. Если установить `null`, Nix не будет создавать `vendor` и использовать зависимости из `go.mod` напрямую. Для проектов без внешних зависимостей это ок.

---

c) `flake.lock` pins nixpkgs. Why is this the single most important file for reproducibility?

`flake.lock` фиксирует конкретную ревизию nixpkgs. Без него Nix каждый раз брал бы самую свежую версию, что сломало бы воспроизводимость.

---


d) `buildGoModule` vs `buildGoApplication` — what's the difference?

`buildGoModule` — стандартный способ сборки Go-проектов в Nix. `buildGoApplication` более сложный, для проектов с несколькими бинарниками. Для QuickNotes достаточно `buildGoModule`.

## Task2

### 2.1 

Обновила `flake.nix`:

```bash
packages.docker = pkgs.dockerTools.buildImage {
  name = "quicknotes";
  tag = "latest";

  contents = [
    pkgs.cacert
    pkgs.busybox
  ];

  config = {
    Cmd = [ "${self.packages.${system}.quicknotes}/bin/quicknotes" ];
    Env = [
      "SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt"
    ];
    ExposedPorts = {
      "8080/tcp" = {};
    };
  };
};
```

Собираю образ:

![alt text](image-4.png)

### 2.2 Доказательство воспроизводимости

Сравнение sha при запуске двух изолированных сред:

![alt text](image-5.png)

SHA совпадает, что доказывает воспроизводимость.

### Сравнение с lab6

```bash
docker build --no-cache -t qn-lab6:run1 ./app
docker build --no-cache -t qn-lab6:run2 ./app
docker images --no-trunc qn-lab6
```

![alt text](image-6.png)

Полученные рузультаты означают, что Docker-сборка недетерминирована, Nix-сборка детерминирована.

### Сравнение размеров образов

### Сравнение размеров

| Образ | Размер | Источник |
|-------|--------|----------|
| `quicknotes:latest` (Nix) | 101 MB | Nix (Lab 11) |
| `qn-lab6:run1` (Docker) | 14.8 MB | Docker (Lab 6) |
| `qn-lab6:run2` (Docker) | 14.8 MB | Docker (Lab 6) |

Выводы из консоли:

Docker:

![alt text](image-7.png)

Nix:

![alt text](image-8.png)

### Ответы на вопросы

e) dockerTools.buildImage produces a deterministic image. What does Docker's docker build do that introduces non-determinism, even from the same Dockerfile + Git SHA?

Docker добавляет временные метки в каждый слой образа, использует порядок файлов при копировании (зависит от файловой системы) и может загружать зависимости из сети, всё это меняет дайджест образа при каждом запуске, даже если код и Dockerfile одинаковы.

---

f) For a security auditor, what can you prove with a reproducible image that you cannot prove with a signed-but-non-reproducible image?

Репродуцируемый образ позволяет пересобрать бинарник из исходного кода и сравнить SHA. Если SHA совпадают, то аудитор может подтвердить, что бинарник действительно собран из этого кода, а не подменён. Подпись без репродуцируемости означает что-то вроде «кто-то сказал, что это правильно».

---

g) What's the trade-off of Nix's reproducibility? Why is docker build still the default for most teams?

Nix даёт детерминизм, но это так же означает сложность, больший размер образов и медленную скорость. Docker же отличается простотой и скоростью. Для большиства команд Docker как раз удобен по этим причинам.

## Bonus

### 

Файл `.github/workflows/nix-repro.yml`:

```bash
name: Nix Reproducibility

on:
  push:
    branches: [ feature/lab11 ]
  pull_request:
    branches: [ main ]

jobs:
  build1:
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@v4
      - uses: cachix/install-nix-action@v31
        with:
          extra_nix_config: |
            experimental-features = nix-command flakes
      - run: nix build .#docker
      - run: sha256sum result > digest1.txt
      - uses: actions/upload-artifact@v4
        with:
          name: digest1
          path: digest1.txt

  build2:
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@v4
      - uses: cachix/install-nix-action@v31
        with:
          extra_nix_config: |
            experimental-features = nix-command flakes
      - run: nix build .#docker
      - run: sha256sum result > digest2.txt
      - uses: actions/upload-artifact@v4
        with:
          name: digest2
          path: digest2.txt

  check:
    runs-on: ubuntu-24.04
    needs: [build1, build2]
    steps:
      - uses: actions/download-artifact@v4
        with:
          name: digest1
      - uses: actions/download-artifact@v4
        with:
          name: digest2
      - run: |
          if [ "$(cat digest1.txt)" != "$(cat digest2.txt)" ]; then
            echo "Digests differ!"
            exit 1
          fi
          echo "Digests match!"
```

### Успешный CI

Первый успешный CI!

https://github.com/kicchhi/DevOps-Intro/actions/runs/29059752334

![alt text](image-9.png)

### Демонстрируем расхождения

build1 соберётся с версией 0.1.1 - дайджест изменился

build2 соберётся с версией 0.1.0 - дайджест стандартный

check падает, потому что дайджесты отличаются.

Сломанный CI: https://github.com/kicchhi/DevOps-Intro/actions/runs/29061679888

```bash
- name: Build with modified version
        run: |
          sed -i 's/version = "0.1.0"/version = "0.1.1"/' flake.nix
          nix build .#docker
```

![alt text](image-10.png)

### Ответы на вопросы

h) What's the difference between "reproducible on my laptop" and "reproducible in CI" that makes the CI proof load-bearing for a security auditor?

Репродуцируемо на моем ноутбуке, означает, что сборка дает одинаковый результат на одной машине. Но CI-доказательство, это воспроизводимый эксперимент в изолированном окружении, который показывает, что сборка запустится и на нее не повлияет файловая система, кэш, и тд.

---

i) Why two parallel jobs instead of one job that runs nix build twice? What could a single-job two-build comparison miss?

Одна джоба с двумя сборками может использовать общий кэш Nix, вторая сборка просто возьмёт готовый результат из /nix/store. Две параллельные джобы на разных раннерах исключают влияние кэша и доказывают, что сборка действительно детерминирована.

---

j) SOURCE_DATE_EPOCH is the canonical env var for forcing build timestamps. Where in your Nix flake would the timestamp normally leak in, and how does dockerTools.buildImage handle it?

Временная метка может просочиться в Go-бинарник через встроенный time пакет, если не задан SOURCE_DATE_EPOCH. dockerTools.buildImage по умолчанию использует created = "1970-01-01T00:00:00Z", что гарантирует фиксированную временную метку для OCI-образа.
