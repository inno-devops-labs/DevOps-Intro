### Примечание по выполнению Lab 4

Данная лабораторная работа выполнена на **Windows 10/11** с использованием следующих инструментов:

- **Git Bash** — для выполнения команд `curl`, `ping`, `nslookup`, `netstat`, `route print`, `ps`, `taskkill`.
- **Wireshark** — для захвата и анализа TCP-пакетов (замена `tcpdump`).
- **PowerShell** — для команд `netstat -ano` и `taskkill`.

Отказ от использования Ubuntu/WSL2 обусловлен тем, что на моей машине не удалось настроить WSL2 из-за системных ограничений и конфликтов разных приложений. Docker Desktop также не удалось запустить в рабочем состоянии. Поэтому для выполнения работы принято решение воспользоваться другими инструментами.

Все ключевые задачи лабораторной работы выполнены:
- **Task 1** — захват и анализ TCP-пакетов выполнен через Wireshark (захват Loopback-интерфейса).
- **Task 2** — отладка сломанного экземпляра выполнена через Git Bash и PowerShell (аналоги `ss`, `journalctl`, `iptables` заменены на `netstat`, `ps`, `taskkill`).

## Task 1

### 1.1 а также 1.2

Запуск сервера: 

![alt text](image.png)

---
В другом окне:
![alt text](image-1.png)

- Запрос POST /notes HTTP/1.1
- Body {"title":"trace me","body":"in flight"}
- Ответ HTTP/1.1 201 Created

---
Wireshark:

![alt text](image-2.png)
SYN, ACK и тд это все про TCP.
По строчкам на скриншоте:

1. SYN (клиент -> сервер)
2. SYN, ACK (сервер -> клиент)
3. ACK (рукопожатие завершено)
4. POST /notes HTTP/1.1 (запрос)
6. HTTP/1.1 201 Created (ответ)
8. FIN, ACK (клиент закрывает соединение)
10. FIN, ACK (сервер закрывает соединение)  

Как раз на скриншотах из wireshark видно трёхэтапное рукопожатие, HTTP-запрос и ответ, и закрытие соединения.

### 1.3 Запуск команд для отладки

Предложенные команды были заменены на аналоги для windows.

| Linux command | Windows equivalent |
|---------------|-------------------|
| `ss -tlnp \| grep :8080` | `netstat -ano \| findstr 8080` | 
| `ip route show` | `route print` | 
| `mtr -rwc 5 localhost` | `ping -n 5 localhost` | 
| `dig +short example.com @1.1.1.1` | `nslookup example.com` | 
| `journalctl --user -u quicknotes -n 20` | *Not available on Windows* | 

1. `netstat -ano | findstr 8080` - что слушает порт 8080

![alt text](image-3.png)

2. `route print` - таблица маршрутизации

![alt text](image-4.png)

3. пингуем localhost, потерь нет, все хорошо

![alt text](image-5.png)

4. `nslookup example.com` - проверка работы DNS

![alt text](image-6.png)

Для последней команды () не нашла аналогов.

### 1.4

**What would you check first if QuickNotes returned 502?**

**Что бы вы проверили в первую очередь, если бы QuickNotes выдал ошибку 502?**

Ответ: ошибка 502 (Baad Gateway) говорит о том, что промежуточный сервер при попытке выполнить запрос, не смог получить запрос от основного сервера. При получениии такой ошибки в первую очередь необходимо проверить, что процесс QuickNotes слушает порт 8080. Порт может быть занят другим приложением. Затем можно проверить доступность через локалхост (;ocalhost:8080/health), посмотреть конфиги и логи ошибок. А еще может быть проблема в DNS сервере.

## Task 2

### 2.1
Попытка запустить сервер дважды ожидаемо заканчивается с ошибкой "address already in use".

Команда: 

```bash
cd app
ADDR=:8080 go run . &
sleep 1
ADDR=:8080 go run . 2>&1 | tee /tmp/qn-broken.log &
sleep 2
ps -ef | grep "go run" | grep -v grep
```

![alt text](image-9.png)

Первый процесс остался жив и висит на фоне, второй, тем временем, упал с ошибкой.

Проверка того, что сервер отвечает:

![alt text](image-10.png)

### 2.2

| Linux command | Windows equivalent |
|---------------|-------------------|
| `ps -ef \| grep quicknotes` | `tasklist \| findstr go` | 
| `ss -tlnp \| grep 8080` | `netstat -ano \| findstr 8080` |
| `curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8080/health` | `curl -s -o nul -w "%{http_code}\n" http://localhost:8080/health` |
| `sudo iptables -L -n -v` | *Not available on Windows* | 
| `dig +short localhost` | `nslookup localhost` |

![alt text](image-11.png)

### 2.3

Как будто я не совсем поняла, какой процесс нужно убивать, но тем не менее.
Был найден процесс, занимающий порт 8080 и завершен при помощи команды `taskkill //PID 17396 //F`.

![alt text](image-12.png)

Командой `netstat -ano | findstr 8080` проверяем, слушает ли еще кто-то порт 8080.

### 2.4 

Вопрос: что системного в подобных сбоях и какие инструменты могли бы их предотвратить?

Ответ: перед запуском не всегда проверяется, занят ли порт, что может привести к проблемам. Например, решить этот вопрос можно при помощи скрипта, который будут убивать процесс перед тем, как занять порт. Также незаменимым инструментом может быть менеджер процессов, который позволяет отслеживать процессы и занятие порты. 