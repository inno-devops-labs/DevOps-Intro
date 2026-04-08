# Lab 10 — Cloud Computing Fundamentals

## Task 1 — Artifact Registries Research

### Cloud Provider Services
- **AWS:** Amazon Elastic Container Registry (ECR)
- **GCP:** Google Artifact Registry
- **Azure:** Azure Container Registry (ACR)

### Comparison Table

| Feature / Provider | AWS (Amazon ECR) | GCP (Artifact Registry) | Azure (ACR) |
| :--- | :--- | :--- | :--- |
| **Supported Artifacts** | Docker, OCI, Helm charts | Docker, OCI, Helm, Python (PyPI), Maven, npm, Apt, Yum | Docker, OCI, Helm charts |
| **Security Scanning** | Native basic scanning (free) & Enhanced (Amazon Inspector) | Native integration with Google Cloud's On-Demand Scanning | Microsoft Defender for Cloud integration |
| **Geo-Replication** | Cross-region replication (manual configuration) | Multi-region repositories natively supported | Native, automated geo-replication (Premium tier) |
| **Pricing Model** | Pay per GB of storage and data transfer out | Pay per GB of storage and data transfer out | Tiered pricing (Basic, Standard, Premium) + storage/network |

### Analysis
**Which registry service would you choose for a multi-cloud strategy and why?**
Я бы выбрал **GCP Artifact Registry**. Основная причина, это универсальность. В отличие от AWS ECR или Azure ACR, которые фокусируются на Docker/OCI образах, сервис от Google организован как универсальное хранилище. Он поддерживает форматы, важные для исследовательских и вычислительных задач (например, прямая интеграция с Python-пакетами). Это позволит хранить в едином месте и контейнеризированные среды, и скомпилированные библиотеки, и наборы данных, избегая необходимости поднимать отдельные серверы для разных типов артефактов. И вообще Google топ.

---

## Task 2 — Serverless Computing Platform Research

### Cloud Provider Services
- **AWS:** AWS Lambda
- **GCP:** Google Cloud Functions (and Cloud Run)
- **Azure:** Azure Functions

### Comparison Table

| Feature / Provider | AWS Lambda | GCP Cloud Functions | Azure Functions |
| :--- | :--- | :--- | :--- |
| **Supported Runtimes** | Node.js, Python, Java, Go, Ruby, C#, Custom | Node.js, Python, Go, Java, .NET, Ruby, PHP | C#, Node.js, Python, Java, PowerShell, Custom |
| **Max Execution Time** | 15 minutes | 9 minutes (up to 60 mins for Gen 2 HTTP) | 10 minutes (Consumption plan), Unlimited (Premium) |
| **Pricing Model** | Per request + execution duration (GB-seconds) | Per request + execution duration (GB-seconds) | Per execution + duration (Consumption plan) |
| **Cold Start Mitigation** | Provisioned Concurrency | Min Instances | Premium Plan pre-warmed instances |
| **Key Differentiator** | Massive ecosystem, deep AWS integration | Seamless integration with Firebase and Cloud Run | "Durable Functions" for complex stateful workflows |

### Analysis & Reflection

**Which serverless platform would you choose for a REST API backend and why?**
Для REST API бэкенда я бы выбрал **AWS Lambda** (в связке с Amazon API Gateway). Это самая зрелая serverless-экосистема на рынке. У неё огромное комьюнити, множеством готовых фреймворков, и она легко масштабируется под любые объемы трафика.

**What are the main advantages and disadvantages of serverless computing?**
**Преимущества:**
1. Отсутствие управления инфраструктурой: не нужно патчить ОС или настраивать серверы.
2. Автоматическое и мгновенное масштабирование от нуля до десятков тысяч запросов.
3. Экономия (Pay-as-you-go): оплата идет только за миллисекунды фактической работы кода.

**Недостатки:**
1. Проблема "Холодного старта": при редких вызовах платформа тратит время на инициализацию среды. Это особенно критично, если функция загружает тяжеловесные библиотеки (например, для работы с матрицами или графами), так как задержка ответа может составить несколько секунд.
2. Жесткие ограничения ресурсов и времени (таймауты до 15 минут делают serverless непригодным для длительных фоновых вычислений).
3. Привязка к вендору. То есть архитектуру, написанную под AWS Lambda, сложно мигрировать в Google Cloud.