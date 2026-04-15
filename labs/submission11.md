# Lab 11 — Reproducible Builds with Nix

## Task 1 — Build Reproducible Artifacts from Scratch

### Nix Derivation (`default.nix`)
```
{ pkgs ? import <nixpkgs> {} }:
pkgs.buildGoModule {
  pname = "app";
  version = "1.0.0";
  src = ./.;
  vendorHash = null;
}
```
*Explanation:* Этот файл использует встроенную в `nixpkgs` функцию `buildGoModule`. Мы передаем имя, версию и исходники (`src = ./.`). Поскольку в нашем `main.go` используются только стандартные библиотеки Go, мы явно указываем `vendorHash = null;`, чтобы Nix не пытался скачивать сторонние зависимости.

### Reproducibility Proof
**Store path from multiple builds:**
```
Build 1: /nix/store/p22frj0r1kpbn0b5vpy5za1njgi81znb-app-1.0.0
Build 2: /nix/store/p22frj0r1kpbn0b5vpy5za1njgi81znb-app-1.0.0
```
Пути оказались абсолютно идентичными после удаления и повторной сборки.

**SHA256 Hash of the binary:**
```
6ad5ba56f161175ad82b44d585e907bb8c11cfd2a27c2a9b568dded82a14554d  ./result/bin/app
```

### Analysis
**Why is Docker not reproducible?**
Традиционный `Dockerfile` не гарантирует воспроизводимость, потому что его инструкции зависят от времени и состояния внешней среды. Например, команда `apt-get install` или скачивание базового образа `FROM golang:latest` завтра может подтянуть уже другие, обновленные версии пакетов. Кроме того, Docker по умолчанию включает в метаданные слоев временные метки (timestamps) создания файлов, из-за чего хеши финальных образов всегда различаются, даже если код не менялся.

**What makes Nix builds reproducible?**
Nix достигает воспроизводимости за счет трех ключевых факторов:
1. **Изоляция (Sandboxing):** Сборка происходит в полностью изолированной среде без доступа к сети (кроме заранее зафиксированных хешами загрузок) и локальным файлам ОС.
2. **Контентная адресация:** Все зависимости строго зафиксированы криптографическими хешами. Если хеш входа (компилятор, исходники, флаги) идентичен, то и результат сборки будет идентичным.
3. **Отсутствие неявного:** Nix перехватывает системные часы во время сборки и устанавливает время модификации всех файлов на "Эпоху Unix" (1 Jan 1970), устраняя проблему разницы временных меток.

**Explanation of the Nix store path format:**
Формат пути в Nix Store выглядит так: `/nix/store/<hash>-<name>-<version>`.
Ключевой элемент здесь — `<hash>` (обычно 32 символа base32). Это криптографический хеш не от самого собранного бинарника, а от **всех входных данных (inputs)**, использованных для его сборки: исходного кода, версии компилятора, скрипта сборки и библиотек. `<name>` и `<version>` добавляются исключительно для удобства чтения человеком.

---

## Task 2 — Reproducible Docker Images with Nix

### Nix Docker Image Definition (`docker.nix`)
```
{ pkgs ? import <nixpkgs> {} }:
let
  myApp = import ./default.nix { inherit pkgs; };
in
pkgs.dockerTools.buildLayeredImage {
  name = "nix-test-app";
  tag = "latest";
  contents = [ myApp ];
  config = {
    Cmd = [ "${myApp}/bin/app" ];
  };
}
```
*Explanation:* Мы используем `dockerTools.buildLayeredImage`, который автоматически анализирует граф зависимостей нашего приложения `myApp` и распределяет их по оптимальным слоям Docker. В `contents` мы передаем наш бинарник, а в `config.Cmd` указываем команду запуска.

### Image Size Comparison & Analysis
**Size comparison:**
```
nix-test-app   latest    b4ce493a422f   56 years ago   3.69MB
```

**Why are Nix-built images smaller and more reproducible?**
Nix-образы занимают минимальный объем памяти, потому что они не содержат полноценную операционную систему (например, Debian или Alpine) и пакетные менеджеры типа `apt`. Nix кладет в образ *только* скомпилированный бинарник и его строгие рантайм-зависимости (closure). Воспроизводимость достигается тем, что `dockerTools` фиксирует дату создания образа на начало эпохи Unix (1970 год) и использует детерминированные алгоритмы упаковки слоев (tar-архивов). (В выводе консоли отлично видно "56 years ago" — это как раз отсылка к 1970 году).

**Practical advantages of content-addressable Docker images:**
1. **Эффективное кеширование:** Так как хеш слоя зависит только от контента, если зависимость (например, `glibc`) не менялась, слой переиспользуется между абсолютно разными приложениями.
2. **Безопасность и аудит:** В образе нет лишних утилит (bash, curl), что минимизирует поверхность атаки. Мы точно знаем граф зависимостей каждого байта.

---

## Bonus Task — Modern Nix with Flakes

### Flake Implementation
**`flake.nix`:**
```
{
  description = "My reproducible app";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  outputs = { self, nixpkgs }: let
    pkgs = nixpkgs.legacyPackages.x86_64-linux;
  in {
    packages.x86_64-linux.default = import ./default.nix { inherit pkgs; };
    devShells.x86_64-linux.default = pkgs.mkShell {
      buildInputs = [ pkgs.go pkgs.gopls ];
    };
  };
}
```

### Reflection
**How do Flakes improve upon traditional Nix expressions?**
Традиционный `default.nix` зависит от глобального канала `<nixpkgs>`, состояние которого зависит от конкретной машины (версия установленного канала у разработчика А может отличаться от разработчика Б). Flakes решают эту проблему, предоставляя файл `flake.lock` (в нашем случае он зафиксировал коммит `4c1018d` от 2026-04-09). Это жестко фиксирует git-коммит источника. Это гарантирует, что и через 5 лет, скачав этот проект, сборка пройдет на абсолютно идентичной версии компилятора и библиотек, независимо от того, какие версии установлены в системе пользователя в данный момент.

**Why is `devShell` better than traditional dev setups?**
`devShell` создает воспроизводимое рабочее окружение. Вместо того чтобы просить новых разработчиков "установите Go версии 1.22 и такие-то тулзы" в README, они просто пишут `nix develop`. Nix скачивает нужные версии инструментов изолированно, не ломая их основную систему и не конфликтуя с глобально установленными пакетами.
