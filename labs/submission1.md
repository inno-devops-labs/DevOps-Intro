# Lab 1

## Task 1 - SSH Commit Signature Verification

### Что такое подписание commit и почему это важно?
Подпись коммитов нужна для подтверждения того, что изменения действительно
сделаны мной (автором) и не были подделаны. Без этого понижается безопасность работы в команде.

### Доказательства настройки SSH
SSH ключ был создан и добавлен в GitHub как Authentication key. После этого был выполнен коммит и пуш, однако данный коммит помечался как Not Verified. После добавления этого же ключа как Signing Key, у меня получилось одновременно делать pull/push и подписывать коммиты.

Выполненные команды для настройки:
1. Генерация ключа: ssh-keygen -t ed25519 -C "kamilyskaa@yandex.ru"
2. Добавление в ssh-agent: ssh-add ~/.ssh/id_ed25519
3. Настройка git для подписи:
- - git config --global user.signingkey ~/.ssh/id_ed25519.pub
- - git config --global gpg.format ssh
- - git config --global commit.gpgsign true

### Скриншот Verified статуса коммитов
![Task 1 verified commits](task_1_verified_commits.jpg)

## Task 2 - PR Template & Checklist

### Описание PR-шаблона

### Скриншот PR с автоматически подставленным шаблоном

### Как PR-шаблоны улучшают сотрудничество

## Трудности
