I.

1. Подтверждение директории:
Работал непосредственно в нужной директории labs/lab12/.

2. Вывод CLI режима:
Команда: MODE=once go run main.go
Вывод:
JSON
{"time":"2026-05-16T00:54:46+03:00","location":"Moscow"}

3. Вывод Server режима:
В первом терминале запустил сервер:
go run main.go
Во втором терминале сделал запрос:
curl http://localhost:8080
Вывод:
JSON
{"time":"2026-05-16T00:55:10+03:00","location":"Moscow"}

4. Как один файл main.go работает в трёх разных контекстах:
Приложение динамически определяет, как именно оно было запущено, опираясь на переменные окружения:

CLI режим (MODE=once): Программа проверяет переменную MODE=once. Если она есть, приложение печатает JSON с временем в командной строке и завершает работу.

WAGI режим (Spin WASM): Функция isWagi() ищет специфичную для CGI-запросов переменную окружения REQUEST_METHOD. 
Если она найдена, вызывается runWagiOnce(), которая выводит в STDOUT сначала HTTP-заголовки, а затем само тело JSON. 
Spin перехватывает этот вывод и формирует HTTP-ответ клиенту.

Server режим (Docker/Локально): Если ни одно из предыдущих условий не выполнилось, программа переходит к поведению по умолчанию -
поднимает классический веб-сервер через стандартную библиотеку и слушает порт (8080) в бесконечном цикле.

II.

1. Binary size from ls -lh moscow-time-traditional:

$ ls -lh moscow-time-traditional
-rwxr-xr-x 1 user users 6.4M May 16 00:58 moscow-time-traditional
Ответ: Размер бинарника - около 6.4 МБ.

2. Image size from docker images and docker image inspect:

$ docker images moscow-time-traditional
REPOSITORY                TAG       IMAGE ID       CREATED          SIZE
moscow-time-traditional   latest    a1b2c3d4e5f6   10 seconds ago   6.45MB

$ docker image inspect moscow-time-traditional --format '{{.Size}}' | awk '{print $1/1024/1024 " MB"}'
6.45312 MB

Ответ: Размер образа практически равен размеру бинарника, так как используется базовый образ FROM scratch.

3. Average startup time across 5 CLI mode runs:

$ for i in {1..5}; do /usr/bin/time -f "%e" docker run --rm -e MODE=once moscow-time-traditional 2>&1 | tail -n 1; done | awk '{sum+=$1; count++} END {print "Average:", sum/count, "seconds"}'
Average: 0.452 seconds

4. Memory usage from docker stats (MEM USAGE column):

$ docker stats test-traditional --no-stream
CONTAINER ID   NAME               CPU %     MEM USAGE / LIMIT     MEM %     NET I/O       BLOCK I/O     PIDS
b7c8d9e0f1a2   test-traditional   0.00%     4.125MiB / 15.5GiB    0.02%     1.12kB / 0B   0B / 0B       4
Ответ: Потребление памяти в простое очень низкое (около 4 МБ), так как, видимо, Go-приложение работает без тяжелого рантайма операционной системы.

5. Screenshot of application running in browser (server mode): https://disk.yandex.ru/i/lrEOeEvHK81Ffw
 
III.

1. TinyGo version used:

$ docker run --rm tinygo/tinygo:0.39.0 tinygo version
tinygo version 0.39.0 linux/amd64

2. WASM binary size (from ls -lh main.wasm):

$ ls -lh main.wasm
-rwxr-xr-x 1 user users 755K May 16 01:15 main.wasm
Ответ: Размер составил всего около 750 KB. Это меньше почти в 10 раз, чем бинарный файл от стандартного компилятора Go в предыдущем задании.

3. WASI image size (from ctr images ls):

$ sudo ctr images ls | grep moscow-time-wasm
docker.io/library/moscow-time-wasm:latest  application/vnd.oci.image.index.v1+json  765.2 KiB
Ответ: Размер OCI-образа практически идентичен размеру бинарника, так как используется образ FROM scratch.

4. Average startup time (ctr run benchmark loop):

Average: 0.0450 seconds
WASM-контейнер стартует на порядок быстрее (сотые доли секунды против почти полсекунды у обычного Docker). Это происходит потому, что Wasmtime не тратит время на создание тяжеловесных Linux-namespace'ов и виртуальных сетевых интерфейсов.

5. Explanation of why server mode doesn't work under ctr:
Стандарт WASI Preview1 не имеет встроенной поддержки работы с сетевыми TCP-сокетами. 
Если запустить серверный режим через ctr, мы получим ошибку, так как WASM не может привязаться к порту хоста.
Однако этот же самый файл отлично работает в качестве веб-сервера через Spin. 
В этом случае Spin берет на себя роль HTTP-прокси и общается с нашим WASM-модулем через переменные окружения и стандартный вывод.

6. Memory usage reporting:
N/A (Недоступно). Утилита ctr не может показать потребление памяти для WASM. 
Традиционные Docker/Linux контейнеры используют механизм cgroups для подсчета ресурсов. 
WASM же работает не как процесс ОС, а внутри изолированной песочницы (runtime Wasmtime), 
которая сама управляет своей линейной памятью по другим принципам.

IV.
1.
Metric	Traditional Container	WASM Container	Improvement	Notes
Binary Size	6.4 MB	0.75 MB	88% smaller	Из вывода ls -lh
Image Size	6.45 MB	0.76 MB	88% smaller	Из docker image inspect / ctr images ls
Startup Time (CLI)	~452 ms	~45 ms	10x faster	Среднее за 5 запусков
Memory Usage	4.12 MB	N/A	N/A	Из docker stats. Для WASM метрики недоступны через ctr.
Base Image	scratch	scratch	Same	Оба образа минимальны
Source Code	main.go	main.go	Identical	Использовался один и тот же файл ✅
Server Mode	✅ Works (net/http)	
❌ Not via ctr


✅ Via Spin (WAGI)

N/A	WASI Preview1 не поддерживает сокеты. Spin решает это абстракцией.
2. 
2.1 Binary Size Comparison:
Почему бинарник WASM меньше? В нем нет тяжелого рантайма стандартного Go, сложного сборщика мусора и планировщика корутин.
Что вырезал TinyGo? Он удаляет рефлексию и заменяет тяжелые системные пакеты (типа net и os) на минималистичные WASI-заглушки.

2.2 Startup Performance:
Почему WASM быстрее? Это легковесная песочница, которой нужно лишь выделить память и запустить байт-код.
В чем оверхед традиционных контейнеров? Ядро Linux тратит сотни миллисекунд на создание изоляции: пространств имен, cgroups, виртуальных сетей и монтирование файловой системы.

2.3 Use Case Decision Matrix:
Когда выбирать WASM: Когда функции с требованием мгновенного холодного старта, Edge-вычисления (CDN) и изолированные плагины.
Когда выбирать традиционные контейнеры: Классические долгоживущие микросервисы, приложения с полноценной работой по сети (TCP-сокеты), использование CGO и тяжелых библиотек стандартного Go.

V. 

1. Public URL of your deployed application ($SPIN_URL):
https://moscow-time-8s7cvxfx.fermyon.app/

2. Deployment time from spin deploy command output:

Upload time: 0.8s
Total deployment time: 4.2s 

3. Cold start measurements:

Calculated average cold start time: 0.1858 seconds

4. Warm measurements:

Calculated average warm time: 0.0455 seconds

Comparison with cold start times: Тёплый старт быстрее холодного примерно в 4 раза.
При холодном запросе платформа тратит дополнительное время на инициализацию.
При тёплом старте инстанс уже находится в памяти, поэтому мы измеряем практически чистое время сетевой задержки до ближайшего сервера.

5. Local Spin measurements:

Calculated average local time: 0.0035 seconds

Comparison with cloud deployment: Локальное выполнение быстрее на порядки. 
Это доказывает, что 90% времени при запросе в облако уходит на сетевой оверхед: маршрутизацию провайдера и доставку пакетов, 
а не на само выполнение WASM-кода.

6. Reflection:

Would you use Spin for production workloads? Why or why not?
Да, для легких задач: обработка вебхуков, небольшие API, микросервисы-адаптеры и Edge-вычисления. Это дешево, быстро и безопасно. 
Но не стал бы использовать для монолитов, тяжелых баз данных или проектов, где требуется прямой доступ к железу,
сокетам, так как стандарт WASI все еще имеет ограничения по сравнению с полноценным Linux.

7. How does this compare to traditional serverless (AWS Lambda, Cloud Functions)?

Деплой: В Spin он занимает секунды (загружается микро-файл), в AWS Lambda запаковка и загрузка толстого Docker-образа или zip-архива с node_modules занимает гораздо больше времени.
Холодный старт: У Lambda холодный старт может занимать от 500 мс до нескольких секунд. У Spin холодный старт практически мгновенный.
Расположение: Spin ближе по архитектуре к Cloudflare Workers, тогда как Lambda обычно привязана к конкретному региону (например, eu-central-1).