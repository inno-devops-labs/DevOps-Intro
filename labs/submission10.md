# Lab 10 — Cloud Computing Fundamentals
## Task 1 
### AWS — Elastic Container Registry (ECR)
Основное:  Хранение Docker-образов, Интеграция с AWS сервисами, Управление доступом через IAM, 
Supported artifacts: Docker images
Integrations: AWS Lambda, ECS / EKS, CI/CD (CodePipeline)

### GCP — Artifact Registry
- Features: Поддержка разных типов артефактов, Региональные репозитории,Гибкая настройка доступа
- Supported artifacts: Docker, npm, Maven, Python packages
- Integrations: Cloud Build, GKE, CI/CD

### Azure — Container Registry (ACR)
- Features: Хранение контейнеров, Поддержка приватных репозиториев, Встроенная безопасность
- Supported artifacts: Docker images, Helm charts
- Integrations: Azure Kubernetes Service (AKS), Azure DevOps

### Comparison Table

Feature           #  AWS ECR  # GCP Artifact Registry  # Azure ACR 
Docker support          ✅          ✅                       ✅ 
Multi-format            ❌          ✅                    частично 
CI/CD integration       ✅          ✅                       ✅ 
Kubernetes integration  ✅          ✅                       ✅ 


### Analysis

Я бы выбрал GCP Artifact Registry для multi-cloud, потому что он поддерживает больше типов артефактов. Это удобно, если использовать разные технологии в проекте.


## Task 2 — Serverless Platforms

### AWS — Lambda
- Features: Запуск кода без серверов, Автоматическое масштабирование
- Runtimes: Python, Node.js, Java, Go
- Pricing:  Оплата за количество запросов и время выполнения
- Performance: Быстрый старт

### GCP — Cloud Functions / Cloud Run
- Features: Просто
  - Cloud Run поддерживает контейнеры
- Runtimes: Python, Node.js, Go и др.
- Pricing: Pay-as-you-go
- Performance:  Хорошее масштабирование, меньше cold start в Cloud Run

### Azure — Functions
- Features: Интеграция с Azure сервисами, Поддержка триггеров (HTTP, таймер и т.д.)
- Runtimes: C#, Python, JavaScript
- Pricing:  Оплата за использование
- Performance: Иногда есть задержка при запуске

### Comparison Table
# Feature                      # AWS Lambda    # GCP     #Azure 
Languages                          много       много     много 
Cold start                         есть        меньше    есть 
Scaling                            авто        авто      авто 

### Analysis

Для REST API я бы выбрал AWS Lambda, потому что она хорошо интегрируется с API Gateway и часто используется в реальных проектах.


## Reflection

### Advantages:
- Не нужно управлять серверами  
- Автоматическое масштабирование  
- Платишь только за использование  

### Disadvantages:
- Cold start  
- Зависимость от провайдера (vendor lock-in)  
- Ограничения по времени выполнения  