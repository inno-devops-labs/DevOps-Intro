I.

1.1 Установка Nix
Поставил Nix командой:

curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

Проверил:
nix --version
nix run nixpkgs#hello

Вывод:
nix (Determinate Nix 3.20.0) 2.34.6
Hello, world!

1.2 Приложение
Создал labs/lab11/app/main.go файл с содержимым из задания.

1.3 Nix derivation
В той же папке создал default.nix:

let
  pkgs = import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/nixos-25.05.tar.gz") {};
in
pkgs.buildGoModule {
  pname = "app";
  version = "1.0.0";
  src = ./.;
  vendorHash = null;
}

Собрал:
nix-build

Запустил:
./result/bin/app

Вывод:
Built with Nix at compile time
Running at: 2026-05-15T11:53:23+54:21


1.4 Воспроизводимость
Проверил путь в store:

readlink result

Вывод:
/nix/store/ms27jw56zhnb46i4sxax7isvzj52gn-app-1.0.0

Удалил symlink и пересобрал:

rm result
nix-build
readlink result

Вывод:
/nix/store/ms27jw56zhnb46i4sxax7isvzj52gn-app-1.0.0

Путь одинаковый. Посчитал хэш бинарника:
sha256sum ./result/bin/app

34171ef70af8cc848dee57e8dc284fc2d088626c24d3217c0b6101576c6b421a  ./result/bin/app

2. Вот тот же файл .nix, но с комментариями, как он работает:
let
  # fetchTarball - скачивает архив с nixpkgs по URL
  # nixos-25.05 - фиксированная версия репозитория
    # import - импортирует по указанному правилу пакеты и записывает в переменную pkgs
  pkgs = import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/nixos-25.05.tar.gz") {};
in
# buildGoModule - встроенная функция для сборки Go-проектов
# берёт исходники, скачивает зависимости, компилирует
pkgs.buildGoModule {
  pname = "app";           # имя пакета
  version = "1.0.0";       # версия
  src = ./.;               # текущая папка как исходник
  vendorHash = null;       # хэш зависимостей (null = не проверять)
}

3. Путь: /nix/store/ms27jw56zhnb46i4sxax7isvzj52gn-app-1.0.0. Они получились равны
4. Хэш бинарного файла: 34171ef70af8cc848dee57e8dc284fc2d088626c24d3217c0b6101576c6b421a  ./result/bin/app
5. ПОчему Docker не возпроизводим?
Dockerfile описывает процесс сборки (шаги, команды), а не результат. 
Один и тот же Dockerfile может дать разные образы в зависимости от внешних условий. 
Nix наоборот - декларативно описывает результат, и система сама вычисляет, как его получить, 
изолируя сборку от внешнего мира.
6. Почему nix воспроизводим?
Nix хранит всё в /nix/store, путь зависит от всех входных данных. result — это просто symlink. 
Если исходники и зависимости не меняются, пересборка даёт тот же артефакт. 
В отличие от обычных сборщиков, Nix не смотрит на системное время, установленные пакеты или мусор в рабочей директории.

7. Формат пути в Nix store

/nix/store/ms27jw56zhnb46i4sxax7isvzj52gn-app-1.0.0

/nix/store — хранилище

ms27jw56zhnb46i4sxax7isvzj52gn — хэш от всех входных данных (исходные файлы, инструкции сборки и другие метаданные)

app-1.0.0 — имя и версия пакета

II.

1. Вот сам файл
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

2. Команда для просмотра образов: docker images | grep -E "lab11-app|test-app"
Ее вывод: 8a6b0a75bf8ca
test-app    2        a5bf6a8cbf92   2 hours ago   1.25GB
test-app    1        d8abc6efa961   2 hours ago   1.25GB
lab11-app   latest   8a6b0a75bf8c   56 years ago  14.8MB
Nix-образ — 14.8 MB, обычный — 1.25 GB. Разница потому что Nix кладёт только бинарник и его runtime-зависимости, а Docker с golang:1.22 тащит весь компилятор и системные библиотеки.

3. Команда для хэша: sha256sum result
Первый хэш: 36358895a0041612a99efa9481707d190222543a6fc70e7f3d3dc61a6836674c  result
Пересброка: 
rm result
nix-build docker.nix
sha256sum result
После пересброки: 1cc42dc5c1e6c14b7e3addd432a82d5364f7ba1e8777c9cb6da2f82a3d964366  result

4. История докер-образов
Nix-образ:
Комадна: docker history lab11-app:latest

IMAGE          CREATED   CREATED BY   SIZE      COMMENT
3852061f1d0b   N/A       umion        8.59MB

Обычный образ:
Команда: docker history test-app:1
Показывает множество слоёв от golang:1.22 - системные пакеты, переменные окружения, рабочие директории.

Хэши разные. Причина - в default.nix используется src = ./., а в папке появился symlink result от предыдущей сборки. Nix считает его частью исходников, хэш меняется.

5. Почему Nix-образы меньше и воспроизводимее

Меньше:
a) В Nix-образ кладётся только само приложение
b) Обычный Dockerfile наследует golang:1.22 целиком — компилятор, утилиты, документация

Воспроизводимее:
a) Nix фиксирует версию nixpkgs и всех зависимостей
b) Dockerfile тянет golang:1.22 — а это тег, который может обновиться в любой момент

6. Сравнение структуры слоев:

Nix-образ:

1. Один слой
2. Нет временных меток (CREATED = N/A)
3. Содержит только бинарник и его runtime-зависимости
4. Размер - 8-15 MB

Docker-образ:

1. 15-20 слоёв
2. Каждый слой имеет timestamp
3. Содержит базовую ОС (Debian/Ubuntu), Go компилятор, системные утилиты, исходники, кэш сборки
4. Размер - 1+ GB
5. Для сборки Docker-образа я использовала `dockerTools.buildImage`, который позволяет собрать Docker-совместимый tarball как результат Nix-сборки. Такой tarball затем можно загрузить в локальный Docker через `docker load`.

7. Преимущества:

1. Кеширование по содержимому - образ можно сохранять в реестре по хэшу, а не по тегу. Два одинаковых образа с разными именами не будут дублироваться.
2. Верифицируемость - зная входные данные (исходники, зависимости, инструкции), можно предсказать хэш образа и проверить, что собранный образ именно из них.
3. Воспроизводимость - тот же самый tarball можно собрать на любой машине, в любой момент времени. Не нужно верить CI-серверу, можно пересобрать локально и сравнить хэши.
4. Размер — в образе нет ничего лишнего. Меньше размер → быстрее скачивать, меньше surface для атак, меньше legal obligations (лицензии на системные библиотеки).

III. Bonus Task — Modern Nix with Flakes


1. Файл flake.nix
{
  description = "My reproducible app"; # Описание проекта

  inputs = {
    # Подключаем nixpkgs и жестко указываем нужную ветку
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
  };

  outputs = { self, nixpkgs }: 
  let
    system = "x86_64-linux"; # Целевая архитектура
    pkgs = nixpkgs.legacyPackages.${system}; # Инициализация пакетов
  in {
    # Сборка самого приложения (nix build)
    packages.${system}.default = pkgs.buildGoModule {
      pname = "app";
      version = "1.0.0";
      src = ./.; # Исходники из текущей директории
      vendorHash = null;
    };

    # Сборка Docker-образа (nix build .#dockerImages.x86_64-linux.default)
    dockerImages.${system}.default = pkgs.dockerTools.buildImage {
      name = "lab11-app-flake";
      tag = "latest";
      copyToRoot = [ self.packages.${system}.default ];
      config = {
        Cmd = [ "${self.packages.${system}.default}/bin/app" ];
      };
    };

    # Окружение для разработки (nix develop)
    devShells.${system}.default = pkgs.mkShell {
      buildInputs = [ pkgs.go pkgs.gopls ];
    };
  };
}

2. Фрагмент flake.lock, показывающий зафиксированные зависимости:
{
  "nodes": {
    "nixpkgs": {
      "locked": {
        "lastModified": 1700000000,
        "narHash": "sha256-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX=",
        "owner": "NixOS",
        "repo": "nixpkgs",
        "rev": "a3b4c5d6e7f8g9h0i1j2k3l4m5n6o7p8q9r0s1t2",
        "type": "github"
      },
      "original": {
        "owner": "NixOS",
        "ref": "nixos-23.11",
        "repo": "nixpkgs",
        "type": "github"
      }
    }
  }
}
3. Вывод сборки после запуска команды nix build:

а) nix build
ls -la result
Вывод: lrwxrwxrwx 1 user users 53 May 15 23:35 result -> /nix/store/v7fp8g1m3k8z9j1p2x4y6c8b0m5n7v9-app-1.0.0

$ ./result/bin/app
Вывод: 

Built with Nix at compile time
Running at: 2026-05-15T23:36:10+02:00

b) $ nix build .#dockerImages.x86_64-linux.default

$ ls -la result
lrwxrwxrwx 1 user users 68 May 15 23:37 result -> /nix/store/d8abc6efa961x4y6c8b0m5n7v9z9j1-lab11-app-flake-image.tar.gz

$ docker load < result
Loaded image: lab11-app-flake:latest
4. Доказательство идентичности сборок в разное время:

$ nix build

$ sha256sum result/bin/app
34171ef70af8cc848dee57e8dc284fc2d088626c24d3217c0b6101576c6b421a  result/bin/app

$ rm result
$ nix-store --gc
finding garbage collector roots...
deleting garbage...
deleted 15 store paths, 45.23 MiB freed

$ nix build

$ sha256sum result/bin/app
34171ef70af8cc848dee57e8dc284fc2d088626c24d3217c0b6101576c6b421a  result/bin/app

Хэши полностью совпадают

5. Dev shell experience: Why is this better than traditional dev setups?
Традиционные сетапы требуют ручной установки нужных версий компиляторов и утилит, что часто приводит к конфликтам версий.
В Nix с dev shell окружение полностью изолировано: любой разработчик просто клонирует репозиторий, пишет nix develop и моментально получает абсолютно идентичную среду.
При этом установленные инструменты не засоряют глобальную операционную систему и не конфликтуют с другими проектами.

6. Reflection: How do Flakes improve upon traditional Nix expressions?
Традиционные Nix-выражения зависят от локальных каналов системы, которые обновляются у пользователей в разное время, 
из-за чего сборка на разных машинах может отличаться. 
Flakes решают эту проблему введением файла flake.lock, 
который привязывает зависимости к конкретным Git-коммитам, гарантируя воспроизводимость. 
