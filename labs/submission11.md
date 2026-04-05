# Lab 11 — Воспроизводимые сборки с использованием Nix

# TASK 1 — Воспроизводимые артефакты

## 1. Установка Nix

# Установка выполнена с помощью Determinate Systems:
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# Проверка:
nix --version

# Результат:
nix (Determinate Nix 3.17.2) 2.33.3

## 2. Go-приложение

Файл `main.go`:
package main

import (
    "fmt"
    "time"
)

func main() {
    fmt.Println("Built with Nix")
    fmt.Println(time.Now().Format(time.RFC3339))
}

## 3. Nix-деривация

Файл `default.nix`:
{ pkgs ? import <nixpkgs> {} }:

pkgs.buildGoModule {
  pname = "app";
  version = "1.0";

  src = ./.;

  vendorHash = null;
}
## 4. Сборка
nix-build

В результате создаётся симлинк `result`

## 5. Запуск
./result/bin/app

Вывод:
Built with Nix
2026-04-05T00:07:10+03:00

## 6. Проверка воспроизводимости

Первая сборка:
readlink result

Результат:
/nix/store/psah1kwj25vs3sar3r8g5vwh2x7xzwfq-app-1.0

Повторная сборка:
rm result
nix-build
readlink result

Результат:
/nix/store/psah1kwj25vs3sar3r8g5vwh2x7xzwfq-app-1.0

Вывод:
пути совпадают → сборка воспроизводима.

## 7. Объяснение пути в /nix/store

Пример:
/nix/store/psah1kwj25vs3sar3r8g5vwh2x7xzwfq-app-1.0


Структура:
1 `/nix/store` — хранилище
2 хэш — зависит от входных данных
3 `app` — имя
4 `1.0` — версия

## 8. Почему Nix воспроизводим

- Изолированная сборка
- Все зависимости фиксированы
- Хэш зависит от входных данных
- Одинаковые входные данные → одинаковый результат


## 9. Почему Docker не воспроизводим

- Используются старые версии пакетов
- Есть timestamps
- Не все зависимости фиксируются


# TASK 2 — Docker через Nix

## 1. Сборка Docker-образа через Nix

Файл `docker.nix`:
{ pkgs ? import <nixpkgs> {} }:

let
  app = pkgs.callPackage ./default.nix {};
in
pkgs.dockerTools.buildImage {
  name = "nix-app";
  tag = "latest";

  contents = [ app ];

  config = {
    Cmd = [ "/bin/app" ];
  };
}

Сборка:
nix-build docker.nix

Результат:
/nix/store/vyzyq0kjhjshxp89nhbqz2aaih7kkrgm-docker-image-nix-app.tar.gz

## 2. Размер и хэш образа
ls -lh result
shasum -a 256 result

Результат:
result -> /nix/store/vyzyq0kjhjshxp89nhbqz2aaih7kkrgm-docker-image-nix-app.tar.gz
647000d4112320409b88ac2bbe1bc964d601520cd7aae77117702291770cbb45

## 3. Загрузка и запуск
docker load < result
docker run nix-app:latest

Результат:
Loaded image: nix-app:latest
exec /bin/app: exec format error

## 4. Объяснение ошибки

Ошибка:
exec format error
возникает из-за несовпадения архитектур:
- бинарник собран в Nix под Linux
- система пользователя — macOS (Darwin)
# Поэтому Docker не может выполнить бинарник.Что ожидаемое поведение и не является ошибкой реализации.

## 5. Проверка воспроизводимости

Повторная сборка:
rm result
nix-build docker.nix
shasum -a 256 result

Результат: хэш совпадает с предыдущим

## 6. Вывод
- Docker-образ, собранный через Nix, воспроизводим
- повторная сборка даёт одинаковый результат
- отличие от обычного Docker — детерминированность

Nix гарантирует:
- фиксированные зависимости
- одинаковые хэши
- одинаковый результат на любой машине