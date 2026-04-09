## Task 1. Artifact Registries

- AWS → Amazon Elastic Container Registry
- GCP → Google Artifact Registry
- Azure → Azure Container Registry

### Сравнительная таблица

| Параметр   | AWS ECR                                     | GCP Artifact Registry                        | Azure ACR                             |
| ---------- | ------------------------------------------- | -------------------------------------------- | ------------------------------------- |
| Типы       | Docker (фактически OCI)                     | Мульти (npm, Maven и др.)                    | Docker + OCI                          |
| Security   | +                                           | +                                            | +                                     |
| Интеграции | AWS                                         | GCP                                          | Azure/GitHub                          |
| Pricing    | Pay-as-you-go (хранение + исходящий трафик) | Pay-as-you-go (хранение + операции + трафик) | Tier-based (Basic, Standard, Premium) |

Лучший выбор - **GCP Artifact Registry**, так как поддерживает разные типы артефактов

---
## Task 2. Serverless

- AWS → AWS Lambda
- GCP → Google Cloud Run / Functions
- Azure → Azure Functions

###  Сравнительная таблица

| Параметр   | AWS Lambda | GCP Cloud Run             | Azure Functions     |
| ---------- | ---------- | ------------------------- | ------------------- |
| Модель     | Event      | Контейнеры                | Event               |
| Языки      | Много      | Любые (т.к. в контейнере) | Много               |
| Max time   | 15 мин     | до 60 мин                 | до 60 мин (Premium) |
| Cold start | Средний    | Низкий                    | Выше                |
| Гибкость   | Средняя    | Высокая                   | Средняя             |

Лучший выбор - **GCP Cloud Run**, так как имеет меньшие ограничения

Преимущества serverless, в том, что мы платим разумную цену за то, чем реально пользуемся. В случае, если нам не требуются какие-то ресурсы, мы за них не платим и они нам не предоставляются автоматически.

---
