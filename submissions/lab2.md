# Lab 2 Submission

## Task 1 — Git Object Model and Reflog Recovery

### 1.1 Git Object Model

#### HEAD SHA

Для определения commit, на который указывает текущий `HEAD`, была выполнена команда:

```bash
git rev-parse HEAD
```

Output:

```text
44aa9b63f26b0e725fe783694d20d3cf10927d7b
```

Таким образом, в начале исследования `HEAD` указывал на commit:

```text
44aa9b63f26b0e725fe783694d20d3cf10927d7b
```

---

#### Тип объекта HEAD

Команда:

```bash
git cat-file -t HEAD
```

Output:

```text
commit
```

Это показывает, что `HEAD` в данном случае разрешается в Git object типа `commit`.

---

#### Содержимое commit object

Команда:

```bash
git cat-file -p HEAD
```

Output:

```text
tree dd55e0849ff278be4fb0b125752839032027939f
parent 93f221680d94913b64d06c138e66158106ca4f32
author AlisaRyba <evdosenko.dds@gmail.com> 1790849107 +0300
committer AlisaRyba <evdosenko.dds@gmail.com> 1790849107 +0300
gpgsig -----BEGIN SSH SIGNATURE-----
 U1NIU0lHAAAAAQAAADMAAAALc3NoLWVkMjU1MTkAAAAg+e1PVp29QmhYsWEEMXIDfKbGQg
 +/1lnHBvFUwdL+saYAAAADZ2l0AAAAAAAAAAZzaGE1MTIAAABTAAAAC3NzaC1lZDI1NTE5
 AAAAQHeXo+KA0OLgyTtSosCC5qeR+rZ8MkoKG23UYiKuzLMJGXGJCQ7h/E64V+3Hq1oZEv
 tOtU0zC1auI005V7VQQwI=
 -----END SSH SIGNATURE-----

Revert "docs(lab1): document task 2 logs"

This reverts commit 93f221680d94913b64d06c138e66158106ca4f32.
```

Commit object содержит ссылку на root tree:

```text
dd55e0849ff278be4fb0b125752839032027939f
```

а также ссылку на parent commit:

```text
93f221680d94913b64d06c138e66158106ca4f32
```

Помимо этого, commit содержит данные автора, committer, commit message и SSH signature.

---

#### Tree object

Для исследования snapshot repository был открыт tree object:

```bash
git cat-file -p dd55e0849ff278be4fb0b125752839032027939f
```

Output:

```text
040000 tree d0f15a494317a8a43f617b9d4784429b9c5167ab	.github
100644 blob 1c0a1e94b7bbdd951f456cda51af6b8484cc3cee	.gitignore
100644 blob 4137b3baaa91461c49337bc78a99673d26d11f19	README.md
040000 tree 7d0898a908e274ea809722844cdbd836f3b1c05a	app
040000 tree 5b4aec0c1dc6cb033fa8b48348b2477ebd3f1f0b	labs
040000 tree 49b5a97bdb968d5bd602e7e06d5d188d536dcf43	lectures
```

Tree object описывает структуру соответствующего snapshot.

Например:

```text
040000 tree ... app
```

указывает на другой tree object, представляющий directory `app/`.

Запись:

```text
100644 blob 1c0a1e94b7bbdd951f456cda51af6b8484cc3cee .gitignore
```

связывает имя файла `.gitignore` с blob object, содержащим фактическое содержимое этого файла.

---

#### Blob object

Для исследования был выбран blob файла `.gitignore`:

```bash
git cat-file -p 1c0a1e94b7bbdd951f456cda51af6b8484cc3cee
```

Output:

```text
# ⚠️  KEEP THIS FILE MINIMAL.
#
# This .gitignore is inherited by every student fork. Anything listed here
# is something a student CANNOT `git add` without `-f`. So this file must
# ONLY contain:
#   (a) instructor-only paths (refs/), and
#   (b) machine-generated junk that NOBODY should ever commit.
#
# Do NOT add lab DELIVERABLES here (scan reports, SBOMs, go.sum, k8s
# manifests, CI workflows, Dockerfiles, playbooks, dashboards, …). Students
# are told to commit those in their submission PRs — ignoring them upstream
# silently breaks the lab. When in doubt, leave it OUT of this file.

# ── Instructor-only ─────────────────────────────────────────────
# Reference submissions (dry-run worked examples). Never pushed upstream;
# students never see these. This is the one path that is intentionally hidden.
refs/

# ── Machine-generated junk (no one commits these) ───────────────
# Compiled binaries / local runtime state
app/quicknotes
app/data/
/quicknotes
*.exe

# Vagrant runtime state (Lab 5) — the Vagrantfile IS committed; .vagrant/ is not
.vagrant/

# Nix build symlinks (Lab 11) — flake.nix + flake.lock ARE committed; result is not
result
result-*

# Terraform state — MUST never be committed (can contain secrets)
*.tfstate
*.tfstate.backup
.terraform/

# Python virtualenvs / caches
.venv/
__pycache__/
*.pyc

# Editor / IDE
.vscode/
.idea/
*.swp

# OS noise
.DS_Store
Thumbs.db

# Local agent config (not part of the course)
.claude/

# NOTE: deliberately NOT ignored, because students commit them as lab evidence:
#   submissions/labN.md        (lab reports)
#   .github/workflows/*.yml    (Lab 3 CI)
#   Dockerfile, compose.yaml   (Lab 6)
#   ansible/                   (Lab 7)
#   monitoring/                (Lab 8)
#   *.sbom.cdx.json, zap-*.html/json, trivy-*.txt   (Lab 9 scan evidence)
#   flake.nix, flake.lock      (Lab 11)
#   wasm/main.go, spin.toml, go.sum   (Lab 12)
```

Таким образом, была полностью прослежена цепочка:

```text
HEAD
  ↓
commit 44aa9b63...
  ↓
tree dd55e084...
  ↓
blob 1c0a1e94...
  ↓
.gitignore contents
```

Git не хранит commit как просто набор файлов. Commit ссылается на tree object, tree связывает имена файлов и директорий с другими trees и blobs, а blob хранит содержимое конкретного файла.

---

### 1.2 Internal Structure of `.git`

Для исследования внутренней структуры repository была выполнена команда:

```bash
ls -la .git/
```

Output:

```text
total 64
drwxr-xr-x@ 15 alisaevdosenko  staff   480  2 окт.  10:06 .
drwxr-xr-x@ 11 alisaevdosenko  staff   352  1 окт.  12:56 ..
-rw-r--r--@  1 alisaevdosenko  staff   373  1 окт.  13:05 COMMIT_EDITMSG
-rw-r--r--@  1 alisaevdosenko  staff   504 30 сент. 21:08 config
-rw-r--r--@  1 alisaevdosenko  staff    73 30 сент. 20:21 description
-rw-r--r--@  1 alisaevdosenko  staff   795  2 окт.  10:08 FETCH_HEAD
-rw-r--r--@  1 alisaevdosenko  staff    21  1 окт.  13:03 HEAD
drwxr-xr-x@ 16 alisaevdosenko  staff   512 30 сент. 20:21 hooks
-rw-r--r--@  1 alisaevdosenko  staff  3183  1 окт.  13:05 index
drwxr-xr-x@  3 alisaevdosenko  staff    96 30 сент. 20:21 info
drwxr-xr-x@  4 alisaevdosenko  staff   128 30 сент. 20:21 logs
drwxr-xr-x@ 50 alisaevdosenko  staff  1600  2 окт.  10:08 objects
-rw-r--r--@  1 alisaevdosenko  staff    41  1 окт.  13:04 ORIG_HEAD
-rw-r--r--@  1 alisaevdosenko  staff   112 30 сент. 20:21 packed-refs
drwxr-xr-x@  5 alisaevdosenko  staff   160 30 сент. 20:21 refs
```

Основные элементы `.git` имеют следующие роли:

- `HEAD` — указывает на текущую branch или непосредственно на commit в detached HEAD state;
- `refs/` — содержит references на branches и tags;
- `objects/` — object database Git, где хранятся commits, trees, blobs и tag objects;
- `logs/` — содержит reflog information;
- `index` — представляет staging area;
- `config` — содержит локальную конфигурацию repository;
- `ORIG_HEAD` — используется Git для сохранения предыдущего положения `HEAD` при некоторых операциях;
- `packed-refs` — может содержать branches/tags в упакованном виде.

`.git/HEAD` обычно указывает на текущую branch через symbolic reference. `refs/heads/` содержит references локальных branches, а `objects/` является object database Git. Часть objects хранится как loose objects, а Git также может объединять их в packfiles для более эффективного хранения.

> **Дополнительные outputs для этого раздела будут добавлены перед submission:**
>
> ```bash
> cat .git/HEAD
> ls .git/refs/heads/
> ls .git/objects/ | head
> find .git/objects -type f | wc -l
> ```

---

### 1.3 Reflog Recovery

Для симуляции потери данных в `feature/lab2` были созданы два commits:

```text
3b8b090 wip(lab2): more progress
66b9195 wip(lab2): start
```

История перед destructive reset выглядела так:

```text
3b8b090 (HEAD -> feature/lab2) wip(lab2): more progress
66b9195 wip(lab2): start
44aa9b6 (origin/main, origin/HEAD, main) Revert "docs(lab1): document task 2 logs"
93f2216 docs(lab1): document task 2 logs
5fb2281 docs: add PR template
```

Текущий full SHA перед reset:

```bash
git rev-parse HEAD
```

Output:

```text
3b8b090baf9888b8048220874918ee7bf8890077
```

---

#### Destructive Reset

Для намеренной симуляции ошибки была выполнена команда:

```bash
git reset --hard HEAD~2
```

Output:

```text
HEAD is now at 44aa9b6 Revert "docs(lab1): document task 2 logs"
```

После reset:

```bash
git status
```

Output:

```text
On branch feature/lab2
nothing to commit, working tree clean
```

Обычный `git log` больше не показывал Lab 2 commits:

```text
44aa9b6 (HEAD -> feature/lab2, origin/main, origin/HEAD, main) Revert "docs(lab1): document task 2 logs"
93f2216 docs(lab1): document task 2 logs
5fb2281 docs: add PR template
bad2887 (upstream/main, upstream/HEAD) docs(lab10): add GitHub Codespaces as Task 2 fallback for Render
c42ec18 docs(lab10): move Task 2 from Hugging Face Spaces to Render free tier
```

Это произошло потому, что branch pointer `feature/lab2` был перемещён на два commits назад.

---

#### Reflog

Команда:

```bash
git reflog
```

показала предыдущие состояния `HEAD`:

```text
44aa9b6 (HEAD -> feature/lab2, origin/main, origin/HEAD, main) HEAD@{0}: reset: moving to HEAD~2
3b8b090 HEAD@{1}: commit: wip(lab2): more progress
66b9195 HEAD@{2}: commit: wip(lab2): start
44aa9b6 (HEAD -> feature/lab2, origin/main, origin/HEAD, main) HEAD@{3}: checkout: moving from main to feature/lab2
44aa9b6 (HEAD -> feature/lab2, origin/main, origin/HEAD, main) HEAD@{4}: revert: Revert "docs(lab1): document task 2 logs"
93f2216 HEAD@{5}: checkout: moving from main to main
93f2216 HEAD@{6}: commit: docs(lab1): document task 2 logs
5fb2281 HEAD@{7}: checkout: moving from feature/lab1 to main
6a76b11 (origin/feature/lab1, feature/lab1) HEAD@{8}: commit: docs(lab1): add images
ea312b3 HEAD@{9}: commit: docs(lab1): document task 2, 3
b00d7e8 HEAD@{10}: checkout: moving from main to feature/lab1
5fb2281 HEAD@{11}: checkout: moving from feature/lab1 to main
b00d7e8 HEAD@{12}: commit: docs(lab1): document task 1
4886dbd HEAD@{13}: checkout: moving from feature/lab1 to feature/lab1
4886dbd HEAD@{14}: checkout: moving from main to feature/lab1
5fb2281 HEAD@{15}: commit: docs: add PR template
bad2887 (upstream/main, upstream/HEAD) HEAD@{16}: checkout: moving from feature/lab1 to main
4886dbd HEAD@{17}: commit: docs(lab1): start submission
```

Reflog сохранил запись о том, что до reset `HEAD` находился на:

```text
3b8b090
```

---

#### Recovery

Потерянная работа была восстановлена командой:

```bash
git reset --hard 3b8b090
```

Output:

```text
HEAD is now at 3b8b090 wip(lab2): more progress
```

После восстановления история снова содержала оба Lab 2 commits:

```text
3b8b090 (HEAD -> feature/lab2) wip(lab2): more progress
66b9195 wip(lab2): start
44aa9b6 (origin/main, origin/HEAD, main) Revert "docs(lab1): document task 2 logs"
93f2216 docs(lab1): document task 2 logs
5fb2281 docs: add PR template
```

Содержимое `submissions/lab2.md` также было восстановлено:

```bash
cat submissions/lab2.md
```

Output:

```text
important work
more important work
```

Таким образом, `reset --hard` не уничтожил commit objects мгновенно. Он переместил branch reference, а предыдущие положения `HEAD` остались доступны через `reflog`.

---

### 1.4 Что произошло бы при `git gc`

После `reset --hard` потерянные commits становятся недостижимыми из текущей branch, но некоторое время остаются в Git object database и доступны через `reflog`.

Обычный `git gc` обычно не удаляет свежие unreachable objects немедленно благодаря retention periods. Однако aggressive garbage collection или использование `--prune=now` после исчезновения соответствующих reflog references может физически удалить эти objects.

После фактического удаления объектов из object database восстановление через `reflog` уже может стать невозможным. Поэтому `reflog` является полезным recovery mechanism, но не заменяет полноценный backup.

---

# Task 2 — Signed Release Tag and Rebase

## 2.1 Signed Annotated Tag

Для Lab 2 был создан signed annotated tag:

```text
v0.1.0-lab2-alisaevdosenko
```

Проверка типов tags была выполнена командой:

```bash
git tag -l --format='%(refname:short) %(objecttype) %(*objecttype)'
```

Output:

```text
v0.0.1 tag commit
v0.1.0-lab2-alisaevdosenko tag commit
v1.0 commit
```

Для:

```text
v0.1.0-lab2-alisaevdosenko
```

значение:

```text
tag commit
```

означает, что reference указывает на отдельный annotated tag object, который в свою очередь ссылается на commit.

Для сравнения:

```text
v1.0 commit
```

указывает непосредственно на commit и является lightweight tag.

---

### Signature Verification

Signature созданного Lab 2 tag была проверена:

```bash
git tag -v "v0.1.0-lab2-${USER}"
```

Output:

```text
object 44aa9b63f26b0e725fe783694d20d3cf10927d7b
type commit
tag v0.1.0-lab2-alisaevdosenko
tagger AlisaRyba <evdosenko.dds@gmail.com> 1790929709 +0300

Lab 2 milestone — version control deep dive
Good "git" signature for evdosenko.dds@gmail.com with ED25519 key SHA256:Q7ijWjKndttr1JGzwLbdqqHIBHBt92SVt6n1rI2AxEA
```

Строка:

```text
Good "git" signature for evdosenko.dds@gmail.com
```

подтверждает успешную криптографическую проверку SSH signature tag.

---

## 2.2 Rebase Feature Branch

Для моделирования ситуации, когда `main` изменился во время работы над feature branch, в `main` был создан commit:

```text
f8876d9 docs: upstream moved while you worked
```

### История до rebase

До rebase граф выглядел следующим образом:

```bash
git log --oneline --graph --decorate --all -15
```

Output:

```text
* f8876d9 (origin/main, origin/HEAD, main) docs: upstream moved while you worked
| * 3b8b090 (HEAD -> feature/lab2) wip(lab2): more progress
| * 66b9195 wip(lab2): start
|/
* 44aa9b6 (tag: v1.0, tag: v0.1.0-lab2-alisaevdosenko) Revert "docs(lab1): document task 2 logs"
* 93f2216 docs(lab1): document task 2 logs
* 5fb2281 docs: add PR template
| * 6a76b11 (origin/feature/lab1, feature/lab1) docs(lab1): add images
| * ea312b3 docs(lab1): document task 2, 3
| * b00d7e8 docs(lab1): document task 1
| * 4886dbd docs(lab1): start submission
|/
* bad2887 (upstream/main, upstream/HEAD) docs(lab10): add GitHub Codespaces as Task 2 fallback for Render
* c42ec18 docs(lab10): move Task 2 from Hugging Face Spaces to Render free tier
* 9f41b7d docs(lab7): make seed.json shipping explicit; require bonus artifacts, not logs
* 8de962e docs(lab11): fix nixpkgs pin vs go.mod collision; add network fallback pitfalls
* bfa345b docs(lab3): matrix renames required checks — warn + ci-ok gate pattern; set honest cache expectations
```

До rebase `feature/lab2` содержала commits:

```text
66b9195 wip(lab2): start
3b8b090 wip(lab2): more progress
```

и расходилась с `main`, в которой появился новый commit:

```text
f8876d9 docs: upstream moved while you worked
```

---

### История после rebase

После rebase граф стал линейным:

```text
* 036782e (HEAD -> feature/lab2) wip(lab2): more progress
* eba70b1 wip(lab2): start
* f8876d9 (origin/main, origin/HEAD, main) docs: upstream moved while you worked
* 44aa9b6 (tag: v1.0, tag: v0.1.0-lab2-alisaevdosenko) Revert "docs(lab1): document task 2 logs"
* 93f2216 docs(lab1): document task 2 logs
* 5fb2281 docs: add PR template
| * 6a76b11 (origin/feature/lab1, feature/lab1) docs(lab1): add images
| * ea312b3 docs(lab1): document task 2, 3
| * b00d7e8 docs(lab1): document task 1
| * 4886dbd docs(lab1): start submission
|/
* bad2887 (upstream/main, upstream/HEAD) docs(lab10): add GitHub Codespaces as Task 2 fallback for Render
* c42ec18 docs(lab10): move Task 2 from Hugging Face Spaces to Render free tier
* 9f41b7d docs(lab7): make seed.json shipping explicit; require bonus artifacts, not logs
* 8de962e docs(lab11): fix nixpkgs pin vs go.mod collision; add network fallback pitfalls
* bfa345b docs(lab3): matrix renames required checks — warn + ci-ok gate pattern; set honest cache expectations
```

После rebase Lab 2 commits получили новые SHA:

```text
до rebase:
66b9195
3b8b090

после rebase:
eba70b1
036782e
```

Это произошло потому, что `rebase` не перемещает существующие commits буквально. Он создаёт новые commit objects поверх нового parent commit.

В данном случае новые Lab 2 commits теперь основаны на:

```text
f8876d9
```

из `main`.

---

## 2.3 Почему после rebase нужен `--force-with-lease`

Поскольку rebase изменяет parent commits, изменяются и SHA rebased commits. Из-за этого история локальной `feature/lab2` больше не является обычным fast-forward относительно старой remote branch.

Для обновления remote branch используется:

```bash
git push --force-with-lease origin feature/lab2
```

`--force-with-lease` безопаснее обычного `--force`, поскольку перед перезаписью remote history Git проверяет, что remote branch всё ещё находится в ожидаемом состоянии.

Если другой разработчик успел отправить новые commits после моего последнего `fetch`, `--force-with-lease` должен отказаться от перезаписи branch вместо того, чтобы молча удалить чужую работу.

---

## 2.4 Merge vs Rebase

Я бы использовала `merge`, когда важно сохранить реальную структуру разработки и сам факт существования параллельных branches, особенно при работе с shared branches. Merge не переписывает существующие commit hashes и поэтому безопаснее для истории, которой уже пользуются другие разработчики.

`Rebase` удобен для локальных feature branches перед Pull Request, когда требуется получить более линейную и читаемую историю. Он позволяет перенести feature commits поверх актуального `main`, но создаёт новые commits с новыми SHA.

Я бы избегала rebase commits, которые уже активно используются другими разработчиками, поскольку переписывание shared history может привести к конфликтам и потере чужих изменений.

---

# Conclusion

В Lab 2 были исследованы внутренние структуры Git и продемонстрированы механизмы изменения и восстановления истории.

В Task 1 была прослежена полная object chain:

```text
HEAD → commit → tree → blob → file contents
```

Также был выполнен намеренный `reset --hard`, после которого потерянные commits были найдены в `reflog` и успешно восстановлены.

В Task 2 был создан и проверен SSH-signed annotated tag:

```text
v0.1.0-lab2-alisaevdosenko
```

После изменения `main` feature branch была rebased поверх нового `origin/main`. В результате история стала линейной, а SHA feature commits изменились, что наглядно демонстрирует, что rebase переписывает Git history.
