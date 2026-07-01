# LAb8

Ссылка на PR: https://github.com/inno-devops-labs/DevOps-Intro/pull/1304

## Task1

### Конфигурационные файлы

- [prometheus.yml](https://github.com/kicchhi/DevOps-Intro/blob/feature/lab8/monitoring/prometheus/prometheus.yml)
- [datasource.yml](https://github.com/kicchhi/DevOps-Intro/blob/feature/lab8/monitoring/grafana/provisioning/datasources/datasource.yml)
- [dashboard.yml](https://github.com/kicchhi/DevOps-Intro/blob/feature/lab8/monitoring/grafana/provisioning/dashboards/dashboard.yml)
- [golden-signals.json](https://github.com/kicchhi/DevOps-Intro/blob/feature/lab8/monitoring/grafana/provisioning/dashboards/golden-signals.json)

### Проверка 

Проверяем, что все запустилось и healthy:

![alt text](image.png)

Обращаю вниманиие, что здесь quicknotes: UP

![alt text](image-1.png)

QuickNotes не предоставляет гистограмму для Latency и разделение по статусам для Errors, поэтому эти панели используют quicknotes_http_requests_total как прокси.

![alt text](image-3.png)
![alt text](image-4.png)

### Ответы на вопросы

a) Pull vs push: Prometheus пуллит метрики. Это значит, что QuickNotes не должен быть доступен извне, а Prometheus должен иметь доступ к QuickNotes. Если Prometheus не может достучаться до QuickNotes, метрики не собираются.

b) `scrape_interval: 15s`: Если поставить 5s нагрузка на сервер растёт, но данные точнее. Если 5m данные сглажены, но можно пропустить кратковременные скачки.

c) `rate()` vs `irate()` vs `delta()`: Для Traffic panel лучше `rate()`, так как он сглаживает и показывает среднюю скорость за интервал. `irate()` чувствительнее к шуму, `delta()` показывает изменение за интервал, а не скорость.

d) Почему provisioning из файлов: Чтобы дашборд восстанавливался при каждом запуске и не требовал ручного создания в UI.

## Task2

### Создаем alert

![alt text](image-5.png)

### Генерация ошибок

```bash
for i in {1..100}; do
  curl -s -X POST -H "Content-Type: application/json" -d '{"title":"test"}' http://localhost:8080/notes > /dev/null
done
```

Спустя время Alert перешел в состояние Pending:

![alt text](image-6.png)

А теперь Firing:

![alt text](image-7.png)

### Runbook

[high-error-rate.md](https://github.com/kicchhi/DevOps-Intro/blob/feature/lab8/docs/runbook/high-error-rate.md)

## Ответы на вопросы

e) Почему "sustained for 5 minutes" вместо немедленного срабатывания?

Алерт с задержкой в 5 минут защищает от ложных срабатываний на единичные случайные ошибки (например, один неудачный запрос из-за сетевого флуктуации). Он срабатывает только когда проблема устойчива, что требует вмешательства. Это принцип SRE: "алерт должен означать, что что-то нужно делать прямо сейчас, а не просто зафиксировать событие".

--- 

f)  Оповещения о симптомах и оповещения о причинах: приведенное выше оповещение — это оповещение о симптоме. Какой пример оповещения о причине можно привести для QuickNotes? Почему это хуже?

Пример cause-алерта: "CPU usage > 80% на хосте с QuickNotes".

Он хуже, потому что высокий CPU может быть вызван разными причинами (например, фоновым обновлением системы), но при этом сервис продолжает работать без ошибок для пользователей. Такой алерт будет шумным и отвлекающим, в то время как symptom-алерт (ошибки пользователей) напрямую отражает ухудшение качества сервиса.

---

g) Усталость от оповещений: в лекции 8 говорится, что это более серьезная проблема, чем слишком малое количество оповещений. Какой количественный порог («страница X% времени, когда пользователь не был затронут проблемой») означает, что ваши оповещения слишком навязчивы?

Если более 5% страниц не требуют действий оператора - это признак усталости. SRE практика рекомендует, чтобы доля ложных или не требующих действий алертов была < 5%. Если она выше, инженеры перестают реагировать на алерты, и реальные проблемы остаются незамеченными
