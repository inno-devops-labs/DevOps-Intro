# Task 1:
# 1.
# Blob (test.txt)
# hash: 2eec599a1130d2ff231309bb776d1989b97c6ab2
# содержимое: Test content

# Blob (submission2.md)
# hash: e69de29bb2d1d6434b8b29ae775ad8c2e48c5391
# содержимое: (пусто)

# 2.
# Blob хранит содержимое файла, не содержит имени файла или информации о директории 
# Tree представляет директорию, содержит ссылки на blob-объекты (файлы) и другие tree-объекты, а также их имена и права доступа
# Commit представляет состояние репозитория в определённый момент времени, содержит ссылку на tree-объект, родительский коммит и информацию об авторе и сообщение коммита


# 3
# Git хранит данные как контентно-адресуемую систему. Каждый объект (blob, tree, commit) имеет #уникальный хеш, который зависит от его содержимого.Commit указывает на tree-объект, который #описывает структуру проекта.Tree указывает на blob-объекты (содержимое файлов) и другие #tree-объекты (поддиректории). Каждый коммит представляет полный снимок состояния проекта, а #все объекты связаны между собой через хеши

# Task 2:
# 2.1
# c40fdae (HEAD -> git-reset-practice) Third commit
# 258b239 Second commit
# bc8c115 First commit

# 2.2
# A:
# History (HEAD): переместился с Third commit на Second commit.
# Index (staging): изменения из Third commit остались в индексе 

# B: HEAD is now at bc8c115 First commit
# History (HEAD): с Second commit на First commit
# Index (staging): очищен 
# Working tree: рабочая директория откатилась к состоянию First commit, и в file.txt осталась 
# только строка: First commit

# reflog
# bc8c115 (HEAD -> git-reset-practice) HEAD@{0}: reset: moving to HEAD~1
# 258b239 HEAD@{1}: reset: moving to HEAD~1
# c40fdae HEAD@{2}: commit: Third commit
# 258b239 HEAD@{3}: commit: Second commit
# bc8c115 HEAD@{4}: commit: First commit
# Восстановление “Third commit” через reflog: git reset --hard c40fdae

# Task 3
# 932197b (side-branch) Side branch commit
# c40fdae (HEAD -> git-reset-practice) Third commit
# 258b239 Second commit
# bc8c115 First commit
# 81b7baa (feature/lab1) Add test file
# dd97d27 (origin/feature/lab1) docs: add screenshots for lab1
# 5552e6a docs: add lab1 submission
# 2. Список сообщений коммитов
# Side branch commit
# Third commit
# Second commit
# First commit
# Add test file
# docs: add screenshots for lab1
# docs: add lab1 submission
# 3. git log --graph показывает структуру ветвления репозитория и взаимосвязь коммитов, он помогает увидеть, в какой ветке был создан коммит и как ветки расходятся и объединяются, что упрощает понимание истории проекта
 
# Task 4:
# Создание тега
# Команды:
# git tag v1.0.0
# git show v1.0.0
# git push origin v1.0.0
# Хеш коммита
# Тег v1.0.0 указывает на коммит: c40fdae51deaaba464a293cb174cd98230059f25 (Third commit)

# Теги используются для обозначения релизов
# Они позволяют быстро вернуться к конкретной версии кода, применяются в CI/CD для запуска релизных сборок и помогают организовать версионирование проекта

# Task 5:

# 1: git branch показывает активную ветку со звездочкой *
# 2: как git switch, но команда checkout перегружена и используется также для работы с файлами.
# 3: До restore файл отображается как modified.После restore изменения отменяются.

# Task 6:

# Добавление репозиториев в избранное помогает поддерживать open-source проекты, повышая их видимость, подписка на разработчиков позволяет следить за их работой, изучать лучшие практики и выстраивать профессиональные связи внутри сообщества.