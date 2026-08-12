# Cursor Agent Workflow Starter

Чистый операционный слой для AI-агентов в Cursor. Копируете в **свой** репозиторий и работаете по циклу:

```text
/pplan → /work → /verify → /ship
```

Мелкий срочный фикс целиком: **`/do-all`**.

**Это не приложение.** Только правила, команды и скрипты: как планировать тикеты, писать код, проверять и пушить без хаоса.

Skills написаны под **Cursor**. По возможности используйте **Cursor Grok 4.5**. В другой среде — адаптируйте под своих агентов.

---

## Что внутри

| Часть | Зачем |
| --- | --- |
| GitHub Issues | один тикет = одна задача, план живёт в issue |
| GitHub Project | канбан Backlog → Ready → In progress → In review → Done |
| Cursor Commands | `/pplan`, `/work`, `/verify`, `/ship`, `/do-all` |
| Skills + rules | стиль кода, проверки перед ship, политика моделей |
| `scripts/agent/*` | board / priority / ship / guards |

Состояние тикета хранится **вне чата** (issue body, ветка, `.agent/verify-status-N.json`).

Нет: prod SSH, `/promote`, deploy, restart-скриптов, CI automation с webhook-секретами.

---

## Состав

```text
AGENTS.md
AGENT_OPERATING_RULES.md
docs/
  agent-workflow.md
  onboarding.md
.cursor/
  commands/          # /pplan /work /verify /ship /do-all
  rules/             # model-policy, git-cadence
  skills/
    board-priority/
    do-all/
    project-atlas/   # шаблон карты сервисов
    code-style-* / code-verify-*
scripts/agent/
  board.sh / board.ps1
  priority.sh / priority.ps1
  ship.sh
  lib.sh
  check-secrets.sh
  check-migrations-append-only.sh
agent-config.example.json
.agent/verify-status.example.json
gitignore-agent-snippet.txt
```

---

## Требования

1. [GitHub CLI](https://cli.github.com/) (`gh`), scopes `repo` и `project`:
   ```bash
   gh auth login
   gh auth refresh -s project
   ```
2. Cursor (папка `.cursor/`).
3. Ветки (рекомендуется):
   ```text
   feature/N-slug  →  dev
   ```
   Если `dev` нет — создайте (`git checkout -b dev && git push -u origin dev`) или поправьте `integration_branch` в `agent-config.json` и скрипты.

---

## Быстрая интеграция

### 1. Скопировать в свой репозиторий

```bash
git clone https://github.com/astarooss/agent-workflow-starter.git /tmp/agent-workflow-starter

cp -R /tmp/agent-workflow-starter/.cursor ./
mkdir -p scripts
cp -R /tmp/agent-workflow-starter/scripts/agent ./scripts/

cp /tmp/agent-workflow-starter/AGENTS.md ./
cp /tmp/agent-workflow-starter/AGENT_OPERATING_RULES.md ./
cp /tmp/agent-workflow-starter/agent-config.example.json ./agent-config.json

mkdir -p docs .agent
cp /tmp/agent-workflow-starter/docs/*.md ./docs/
cp /tmp/agent-workflow-starter/.agent/verify-status.example.json ./.agent/
```

Windows: те же пути через `Copy-Item -Recurse`.

### 2. `.gitignore`

Из `gitignore-agent-snippet.txt`:

```gitignore
.agent/*
!.agent/verify-status.example.json
.agent/agent-config.json
```

### 3. GitHub Project (канбан)

1. Репо → **Projects** → New project → Board.
2. Колонки: `Backlog`, `Ready`, `In progress`, `In review`, `Done`.
3. Заполните `CHANGE_ME` в `scripts/agent/board.sh` и `board.ps1`:

```bash
gh project list --owner <OWNER>
gh project field-list <NUMBER> --owner <OWNER>
```

Нужны: `OWNER`, `PROJECT_NUMBER`, `PROJECT_ID`, `STATUS_FIELD_ID`, option id на каждый статус, `REPO` (`owner/name`).

### 4. Labels

```bash
gh label create later --color "ededed" --description "Parked / later" -R <owner>/<repo>
gh label create blocked --color "b60205" --description "Open blocker" -R <owner>/<repo>
gh label create in-progress --color "fbca04" --description "Agent working" -R <owner>/<repo>
```

(`bug` / `enhancement` обычно уже есть. Labels `priority:*` **не нужны**.)

### 5. Priority (опционально, но желательно)

Issue Field `Priority` (Urgent / High / Medium / Low) — см. `docs/onboarding.md`.  
Заполните `scripts/agent/priority.sh` / `priority.ps1`.

### 6. Шаблоны под свой проект

| Файл | Что сделать |
| --- | --- |
| `scripts/agent/board.sh` / `board.ps1` | id доски, Status options, `REPO` |
| `scripts/agent/priority.sh` / `priority.ps1` | Priority field ids |
| `AGENTS.md` | таблица сервисов, scopes |
| `.cursor/skills/project-atlas/SKILL.md` | карта сервисов |
| `code-style-*` / `code-verify-*` | пути и команды под ваш стек |
| `agent-config.json` | `integration_branch` (обычно `dev`) |

Поиск плейсхолдеров: `CHANGE_ME`.

### 7. Права на скрипты

```bash
chmod +x scripts/agent/*.sh
```

### 8. Проверка

```bash
gh auth status
# создать issue → в Cursor: /pplan N → карточка должна уйти в Ready
```

---

## Как пользоваться

1. **`/pplan N`** — план-чеклист в issue, доска → Ready. Кода нет.
2. **`/work N`** — ветка `feature/N-slug` от `dev`, реализация, локальные коммиты с `Refs #N` / `Closes #N`.
3. **`/verify N`** — проверки, `.agent/verify-status-N.json`.
4. **`/ship N`** — после зелёного verify: push + fast-forward `dev`, доска → Done.

Мелкий багфикс end-to-end: **`/do-all N`**.

Подробнее: [`docs/agent-workflow.md`](docs/agent-workflow.md).

---

## Monorepo

```text
your-repo/
  bot/
  api/
  web/
  AGENTS.md
  .cursor/
  scripts/agent/
```

Один тикет может трогать несколько папок. Issues/Project — у этого репо.

---

## Важно

- Не коммитьте `.env`, токены, живые `.agent/verify-status-*.json`.
- Skills/rules можно менять под себя.
- Не обобщайте много работы в один тикет — и не плодите сверхмелкие.
