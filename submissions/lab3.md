# Lab 3 — CI/CD Submission

Frolova AI,    M25-RO-01

a.frolova@innopolis.university

Ссылка на PR: 

**Path:** GitHub Actions. Выбран по той причине, что я постоянно пользуюсь GitHub для демонстрации и хранения проектов.

## Task 1 — PR Gate

### Скриншоты

Первый успешный CI:

![alt text](i1.png)


Сломанный тест:

![alt text](i2.png)
![alt text](i3.png)

Восстановленный тест:

![alt text](i4.png)
![alt text](image-2.png)

Ссылка: https://github.com/kicchhi/DevOps-Intro/actions/runs/27698833264


### Branch protection

Правила защиты были установлены.

![alt text](image-3.png)

### Ответы на вопросы

**a) Why pin runner version instead of ubuntu-latest?**  
Пследняя версия изменится, указывать на конкретную версию надежнее.

**b) Why split vet + test + lint into separate units?**  
Параллельный запуск, быстрая обратная связь. Если олин упадет, остальные будут работать.

**c) What real attack does SHA pinning prevent?**  
Инцидент tj-actions/changed-files, март 2025. Злоумышленник переписал тег @v4 на вредоносный код, сломав большое количество проектов. 

**d) What is `permissions:` and what's the principle behind it?**  
Принцип наименьших привилегий. Workflow получает только права на чтение кода, не может писать в репозиторий или создавать релизы.


## Task 2 — Cache + Matrix + Path Filter

### Optimizations applied
- [x] Кэш (`cache: true`)
- [x] Матрица
- [x] Path filter (`paths: app/**`)

### Timing table

| Сценарий | Время |
|----------|-------|
| Baseline (без кэша) | 42 с |
| С кэшем | ~30 с |
| С кэшем + матрица | 31 с (Go 1.24) |

![alt text](image.png)

Тест с матрицей и кешем оказался провальным на go v1.23, решить проблему не удалось:

![alt text](image-1.png)

### Ответы на вопросы

**f) Why cache `go.sum`-keyed inputs and not build outputs?**  

go.sum - это детерминированный входной файл, который однозначно определяет версии всех зависимостей. Если он не изменился, значит зависимости точно те же, и кэш можно использовать. Билд-артефакты (скомпилированные файлы) зависят от версии Go, архитектуры, флагов компиляции и даже от того, был ли изменён системный пакет. Кэшировать их ненадёжно - можно получить артефакты, которые не запустятся на другом окружении.

**g) What does `fail-fast: false` change in a matrix run?**  

Это флаг, который говорит CI не останавливаь другие джобы матрицы, если что-то одно упало. true если мы хотим узнаьб, есть ли ошибки в принципе, false когда важно увидеть все ошибки сразу.

**h) What's the risk of an attacker writing a cache from a malicious PR?**  

Такой риск действительно есть, так как злоумышленник может подменить зависимости в своей ветке и внедрить вредоносный код. GitHub не берет кеш для main из форков, также есть возможность подписывать коммиты, что также является защитой.
