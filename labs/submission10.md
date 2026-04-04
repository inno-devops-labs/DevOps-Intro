# Submission 10 — Artifact Registries & Serverless Computing

---

# Task 1 — Artifact Registries

## Сервисы

| Провайдер | Контейнеры | Пакеты |
|---|---|---|
| AWS | ECR | CodeArtifact |
| GCP | Artifact Registry | Artifact Registry (всё в одном) |
| Azure | ACR | Azure Artifacts |

## AWS ECR + CodeArtifact
- Форматы: Docker/OCI, npm, Maven, PyPI, NuGet
- Сканирование уязвимостей через Inspector
- Cross-region replication, lifecycle policies
- Интеграции: ECS, EKS, Lambda, CodePipeline
- Цена: $0.10/GB/мес

## GCP Artifact Registry
- Форматы: Docker, Helm, npm, Maven, PyPI, Go, APT, YUM, NuGet — всё в одном сервисе
- Сканирование через Container Analysis
- Remote/Virtual repositories (проксирование из Docker Hub, PyPI)
- Интеграции: Cloud Build, GKE, Cloud Run
- Цена: $0.10/GB/мес

## Azure ACR + Azure Artifacts
- Форматы: Docker/OCI, Helm, npm, Maven, NuGet, PyPI
- Geo-replication (только Premium тир)
- ACR Tasks — сборка образов по триггеру
- Интеграции: AKS, Azure DevOps, GitHub Actions
- Цена: от $0.167/день за тир + хранилище

## Сравнение

| Критерий | AWS | GCP | Azure |
|---|---|---|---|
| Единый сервис | ❌ | ✅ | ❌ |
| Vulnerability scanning | ✅ | ✅ | ✅ |
| Geo-replication | ✅ | ✅ | ✅ (Premium) |
| Pull-through cache | ✅ | ✅ | ✅ |
| Цена хранения | $0.10/GB | $0.10/GB | ~$0.003/GB + tier |

## Вывод

**GCP Artifact Registry** — лучший выбор для multi-cloud: единый сервис для всех форматов, remote repositories, понятная ценовая модель. Для AWS-инфры ECR по-прежнему оптимален за счёт нативных интеграций.

---

# Task 2 — Serverless Computing

## Сервисы

| Провайдер | Основной сервис | Контейнерный вариант |
|---|---|---|
| AWS | Lambda | Lambda Container Image |
| GCP | Cloud Functions | Cloud Run |
| Azure | Azure Functions | Container Apps |

## AWS Lambda
- Рантаймы: Node.js, Python, Java, Go, .NET, Ruby, custom
- Timeout: до 15 мин, память: до 10 GB
- Cold start: 100–500 мс (SnapStart для Java)
- Provisioned Concurrency устраняет cold start
- Триггеры: S3, SQS, DynamoDB, API Gateway, EventBridge и др.
- Цена: $0.20/1M запросов + $0.0000166/GB·сек

## GCP Cloud Functions / Cloud Run
- Рантаймы: Node.js, Python, Go, Java, .NET, Ruby, PHP; Cloud Run — любой контейнер
- Timeout: до 60 мин, память: до 32 GB
- Cold start: 200–800 мс
- Триггеры: Pub/Sub, GCS, Firestore, HTTP, Eventarc
- Цена: $0.40/1M запросов

## Azure Functions
- Рантаймы: C#, JS/TS, Python, Java, PowerShell
- Timeout: 5 мин (Consumption) / 60 мин (Premium), память: до 14 GB (Premium)
- Cold start: 1–3 с; Premium Plan — без cold start
- Durable Functions — stateful workflows
- Цена: $0.20/1M запросов + $0.000016/GB·сек

## Сравнение

| Критерий | AWS Lambda | GCP Cloud Run | Azure Functions |
|---|---|---|---|
| Макс. timeout | 15 мин | 60 мин | 5 / 60 мин |
| Макс. память | 10 GB | 32 GB | 1.5 / 14 GB |
| Cold start | ~300 мс | ~500 мс | ~2 с |
| Без cold start | Provisioned Concurrency | Min instances | Premium Plan |
| Цена/1M запросов | $0.20 | $0.40 | $0.20 |
| Бесплатный tier | 1M req | 2M req | 1M req |

## Вывод: REST API backend

**AWS Lambda + API Gateway** — лучший выбор: минимальный cold start, богатая экосистема триггеров, зрелый инструментарий (SAM, CDK). Если нужны контейнеры или timeout > 15 мин — **GCP Cloud Run**.

## Плюсы и минусы serverless

**Плюсы:**
- Нет управления серверами
- Оплата только за фактическое использование
- Автомасштабирование из коробки

**Минусы:**
- Cold starts неприемлемы для latency-sensitive сервисов без доп. настроек
- Vendor lock-in
- Ограничения по timeout и памяти
- При 24/7 нагрузке — дороже обычных VM