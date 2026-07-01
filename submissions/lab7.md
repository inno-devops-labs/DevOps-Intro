# Lab7

Frolova AI, M25RO-01

a.frolova@innopolis.university

Ссылка на PR:

## Task 1

### Файлы

- [playbook.yaml](https://github.com/kicchhi/DevOps-Intro/blob/feature/lab7/ansible/playbook.yaml)
- [inventory.ini](https://github.com/kicchhi/DevOps-Intro/blob/feature/lab7/ansible/inventory.ini)
- [quicknotes.service.j2](https://github.com/kicchhi/DevOps-Intro/blob/feature/lab7/ansible/templates/quicknotes.service.j2)


![alt text](image.png)

### PLAY RECAP

Запуск `ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml --connection=local`

![alt text](image-1.png)

### curl ounput 

![alt text](image-2.png)

### Ответы на вопросы

a) Разница между command: и модулями (apt, file, copy, systemd)?
command не идемпотентен, выполняет команду каждый раз. Модули идемпотентны, проверяют состояние и меняют только если нужно.

b) notify: и handlers: когда срабатывает, когда нет?
Handler срабатывает только если задача изменила состояние (changed: true). Если задача вернула ok, то handler не вызывается.

c) Variable hierarchy: топ-3 места для переменных?

1. vars: в плейбуке - для локальных переменных
2. group_vars/ - для группы хостов
3. host_vars/ - для конкретного хоста.

d) gather_facts: true — нужно ли для этого playbook?
Да, нужен, чтобы использовать ansible_facts для определения ОС. Без него плейбук не будет работать на разных дистрибутивах. Отключение экономит нескольно секунд на запуск.

## Task2

### Повторный запуск

Видим, что изменений нет

![alt text](image-3.png)

### Изменение переменной

Изменила listen_addr:

![alt text](image-4.png)

Видим, что появились изменения:

![alt text](image-5.png)

### Просмотр изменений

`ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml --check --diff --connection=local`

В отдельном блоке можно просмотреть измменения:

![alt text](image-6.png)

### Ответы на вопросы

1) Why does the second run report `changed=0`?

Модули (`file`, `template`, `systemd`) проверяют текущее состояние системы и изменяют его только если оно отличается от желаемого. Второй запуск видит, что всё уже соответствует состоянию, и ничего не меняет.

---

2) What would happen if you used `shell:` instead of `template:`?

`shell:` не идемпотентен, он выполняет команду каждый раз, даже если файл уже существует. Это привело бы к `changed=1` при каждом запуске, а также к потенциальным ошибкам.

---

3) `--check` is dry-run. `--diff` shows changes. What's the bug you'd catch with `--check --diff`?

`--check --diff` показывает, какие строки изменятся, без применения изменений. Это позволяет обнаружить неожиданные изменения (например, ошибочные пути или неправильные параметры) до того, как они попадут в продакшн.