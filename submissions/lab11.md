# Lab 11

Frolova AI - M25RO-01

a.frolova@innopolis.university

## Task1

### 1.1 flake.nix


### 1.2 Проверка воспроизводимости




Ваш flake.nix (вставьте; flake.lock можно связать)
nix build .#quicknotes выдержка из лога
Два nix-store --query --hash вывода из двух независимых сред — идентичны
./result/bin/quicknotes & + curl /health доказательство того, что он работает
Ответы на вопросы по дизайну от a до d