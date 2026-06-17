# Lab 4 — OS & Networking: Trace, Debug, and Read the Substrate

**Студент:** Руслан Кудинов  
**Дата:** 17.06.2026  

## Task 1 — Trace a Request End-to-End

### Аннотированный вывод tcpdump

Ниже приведён дамп трафика с моими комментариями (выделены ключевые пакеты):

```
22:54:13.257628 IP6 ::1.49264 > ::1.8080: Flags [S], seq 2228672106, win 65476, options [mss 65476,sackOK,TS val 1862712091 ecr 0,nop,wscale 7], length 0
`
.0.(.@.................................p.....j.........0.........
o...........
22:54:13.257655 IP6 ::1.8080 > ::1.49264: Flags [S.], seq 1032698770, ack 2228672107, win 65464, options [mss 65476,sackOK,TS val 1862712091 ecr 1862712091,nop,wscale 7], length 0
`.65.(.@...................................p=......k.....0.........
o...o.......
22:54:13.257673 IP6 ::1.49264 > ::1.8080: Flags [.], ack 1, win 512, options [nop,nop,TS val 1862712091 ecr 1862712091], length 0
`
.0. .@.................................p.....k=........(.....
o...o...
22:54:13.258216 IP6 ::1.49264 > ::1.8080: Flags [P.], seq 1:175, ack 1, win 512, options [nop,nop,TS val 1862712092 ecr 1862712091], length 174: HTTP: POST /notes HTTP/1.1
`
.0...@.................................p.....k=..............
o...o...POST /notes HTTP/1.1
Host: localhost:8080
User-Agent: curl/8.5.0
Accept: */*
Content-Type: application/json
Content-Length: 39

{"title":"trace me","body":"in flight"}
22:54:13.258226 IP6 ::1.8080 > ::1.49264: Flags [.], ack 175, win 511, options [nop,nop,TS val 1862712092 ecr 1862712092], length 0
`.65. .@...................................p=............(.....
o...o...
22:54:13.260416 IP6 ::1.8080 > ::1.49264: Flags [P.], seq 1:177, ack 175, win 512, options [nop,nop,TS val 1862712094 ecr 1862712092], length 176: HTTP: HTTP/1.1 404 Not Found
`.65...@...................................p=..................
o...o...HTTP/1.1 404 Not Found
Content-Type: text/plain; charset=utf-8
X-Content-Type-Options: nosniff
Date: Wed, 17 Jun 2026 19:54:13 GMT
Content-Length: 19

404 page not found

22:54:13.260465 IP6 ::1.49264 > ::1.8080: Flags [.], ack 177, win 511, options [nop,nop,TS val 1862712094 ecr 1862712094], length 0
`
.0. .@.................................p......=..C.....(.....
o...o...
22:54:13.260780 IP6 ::1.49264 > ::1.8080: Flags [F.], seq 175, ack 177, win 512, options [nop,nop,TS val 1862712094 ecr 1862712094], length 0
`
.0. .@.................................p......=..C.....(.....
o...o...
22:54:13.261136 IP6 ::1.8080 > ::1.49264: Flags [F.], seq 177, ack 176, win 512, options [nop,nop,TS val 1862712095 ecr 1862712094], length 0
`.65. .@...................................p=..C.........(.....
o...o...
22:54:13.261165 IP6 ::1.49264 > ::1.8080: Flags [.], ack 178, win 512, options [nop,nop,TS val 1862712095 ecr 1862712095], length 0
`
.0. .@.................................p......=..D.....(.....
o...o...
```

**Аннотация:**
- **SYN** – первый пакет от клиента к серверу (начало TCP handshake)
- **SYN-ACK** – ответ сервера
- **ACK** – подтверждение установки соединения
- **HTTP Request** – запрос `POST /notes HTTP/1.1` с JSON-телом
- **HTTP Response** – ответ сервера `HTTP/1.1 404 Not Found`
- **FIN / FIN-ACK** – завершение соединения

---

### Выводы пяти команд

#### 1. `ss -tlnp | grep :8080`
```
LISTEN 0      4096                *:8080            *:*    users:(("app",pid=17666,fd=3))
```

#### 2. `ip route show`
```
default via 172.26.64.1 dev eth0 proto kernel 
172.26.64.0/20 dev eth0 proto kernel scope link src 172.26.77.149 
```

#### 3. `mtr -rwc 5 localhost`
```
Start: 2026-06-17T23:22:21+0300
HOST: Ruslan    Loss%   Snt   Last   Avg  Best  Wrst StDev
  1.|-- localhost  0.0%     5    0.0   0.1   0.0   0.1   0.0
```

#### 4. `dig +short example.com @1.1.1.1`
```
8.47.69.0
8.6.112.0
```

#### 5. Логи сервера (`ps aux | grep "go run"`)
```
kudin      16008  0.2  0.2 1237684 17428 pts/0   Sl   22:49   0:04 go run .
kudin      19579  0.0  0.0   6868  2304 pts/2    S+   23:22   0:00 grep --color=auto go run
```

---

### Рефлексия: что проверить при 502 Bad Gateway?

Если бы QuickNotes вернул 502, я бы действовал по цепочке:

1. **Проверить, жив ли процесс** – `ps aux | grep quicknotes` или `ps aux | grep "go run"`.  
   Если процесс упал – причина в панике/ошибке, смотреть логи.

2. **Проверить, слушает ли порт** – `ss -tlnp | grep 8080`.  
   Если не слушает – процесс не стартовал или упал, повторить шаг 1.

3. **Проверить достижимость локально** – `curl -v http://localhost:8080/health`.  
   Если недоступен, но порт слушается – возможно, firewall блокирует (проверить `iptables -L`).

4. **Проверить логи** – вывод сервера в консоли или `journalctl`.  
   Там обычно видно, почему запрос не обрабатывается.

5. **Если всё локально работает, а 502 идёт от upstream** – проверить DNS (`dig upstream-host`) и маршруты (`ip route`).

В большинстве случаев 502 – это упавший бэкенд или неправильный upstream, поэтому сначала проверяем процесс, потом порт, потом логи.
