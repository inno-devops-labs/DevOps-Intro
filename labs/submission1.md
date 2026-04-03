# Lab 1 Submission

## Task 1 — SSH Commit Signing 

### Benefits of signed commits
Подписанные коммиты подтверждают, что код действительно написан мной, а не злоумышленником. Это обеспечивает целостность истории изменений и доверие к коду в DevOps пайплайнах.

### Evidence of SSH key setup

git config --global user.signingkey
git config --global commit.gpgSign
git config --global gpg.format

### Why is commit signing important in DevOps?
В DevOps критически важно знать, кто и когда внёс изменения в код. Подписанные коммиты:
- Предотвращают подделку авторства
- Обеспечивают аудит безопасности
- Являются требованием для многих compliance стандартов

## Task 2 — PR Template & Checklist 

### How do PR templates improve collaboration?
PR шаблоны стандартизируют процесс ревью, напоминают о необходимых проверках и экономят время ревьюверов.

### Challenges encountered
Проблем с настройкой не возникло.
