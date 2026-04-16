# Задание 1.

Устанавливал с помощью команды `sh <(curl -L https://nixos.org/nix/install) --daemon`, потому что рекомендованный способ в инструкции просто не сработал! 

Ввести `experimental-features = nix-command flakes` в `~/.config/nix/nix.conf` не смог, потому что файла такого нет.

У меня не сохранился вывод из установки (потому что сказано было, что нужно запустить новый терминал, вот я и закрыл тот, в котором устанавливал; оказывается, зачем-то это нужно было в задании).

Команду пришлось запускать так:
```
osman@MacBook-Pro-Osman nix % nix run nixpkgs#hello --extra-experimental-features nix-command --extra-experimental-features flakes     
evaluation warning: Nixpkgs 26.05 will be the last release to support x86_64-darwin; see https://nixos.org/manual/nixpkgs/unstable/release-notes#x86_64-darwin-26.05
Hello, world!
```

Файл `default.nix`:
```
{ pkgs ? import <nixpkgs> {} }:
pkgs.buildGoModule {
  pname = "testApp";
  version = "1.0.0";
  src = ./.;
  vendorHash = null;
}
```

`buildGoModule` -- это специальная функция, предназначенная для автоматизации сборки Go-проектов. Она знает, как работать с модулями.

Видно, что совпадают пути:
```
osman@MacBook-Pro-Osman app % readlink result
/nix/store/5qppsllshya30xh28snrs2i6wpjcn6jl-testApp-1.0.0
osman@MacBook-Pro-Osman app % rm result
osman@MacBook-Pro-Osman app % nix-build
evaluation warning: Nixpkgs 26.05 will be the last release to support x86_64-darwin; see https://nixos.org/manual/nixpkgs/unstable/release-notes#x86_64-darwin-26.05
/nix/store/5qppsllshya30xh28snrs2i6wpjcn6jl-testApp-1.0.0
osman@MacBook-Pro-Osman app % readlink result
/nix/store/5qppsllshya30xh28snrs2i6wpjcn6jl-testApp-1.0.0
osman@MacBook-Pro-Osman app % 
```

Хэш бинарника:
```
osman@MacBook-Pro-Osman app % sha256sum ./result/bin/my-app
e2ebf5f89492fad51669caa212971b7856a4d9f7fe4ed76731ade4f16b3735b3  ./result/bin/my-app
```

Docker не воспроизводим, потому что результат его выполнения зависит от состояния среды. При запуске команды он может установить другую версию пакета, например.

Nix воспроизводим, потому что выполняется в изолированной среде и настраивает среду так, чтобы она не зависела от времени. Если посмотреть на время создания файла, например, будет указано 56 лет назад.

Формат пути имеет вид `/nix/store/[хэш]-[имя]-[версия]`.
