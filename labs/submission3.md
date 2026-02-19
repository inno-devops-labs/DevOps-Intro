# Task 1

# ссылка на runs: https://github.com/LyubaSch/DevOps-Intro/actions/runs/22184594846

# Workflow был запущен событием push в ветку feature/lab3

# Изученые ключевые концепции:
# Workflow — YAML-файл в .github/workflows/ описывает автоматизацию
# Job — набор шагов, выполняемых на одном runner
# Step — отдельная команда или действие внутри job
# Runner — виртуальная машина (ubuntu-latest), где выполняется job
# Trigger — событие, запускающее workflow (в данном случае push)

# После выполнения push GitHub обнаружил изменение и запустил workflow. Был выделен runner ubuntu-latest. Сначала репозиторий был скачан с помощью actions/checkout, затем выполнены команды для вывода информации. Job завершился успешно (Success)


# Task 2

