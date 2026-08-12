# Contributing

## Стек

- **API**: Python 3.11+, FastAPI, SQLAlchemy (async), SQLite, Alembic
- **Bot**: Python 3.11+, aiogram 3, aiohttp
- **Web**: Node.js 20+, Vue 3, Tailwind CSS, Vite

## Локальная разработка

```bash
# 1. Клонировать репозиторий
git clone https://github.com/mylifeitsbest/tg-support-system.git
cd tg-support-system

# 2. Скопировать и заполнить .env
cp .env.example .env

# 3. Установить зависимости
make install

# 4. Применить миграции
cd api && alembic upgrade head && cd ..

# 5. Запустить
make dev
```

## Git-конвенции

### Ветки

- `main` — стабильная ветка, прямые коммиты запрещены.
- `feature/N-<slug>` — одна ветка на один тикет.
- Всегда создавать ветку от свежего `main`.

### Коммиты

- Conventional Commits: `feat`, `fix`, `test`, `chore`, `refactor`, `docs`, `perf`.
- Скоупы: `api`, `bot`, `web`, `scripts`.
- Тема ≤50 символов, тело ссылается на `#N`.

```
feat(api): add claim endpoint

Refs #3
```

### Тикеты

- Тикеты = GitHub Issues, текст на **русском**.
- Формат заголовка: `[ N ] Краткий заголовок`.
- Код, коммиты, README — на **английском**.

## Агентский воркфлоу

Цикл работы с тикетом:

```
/pplan N  →  /work N  →  /verify N  →  /ship N
```

| Команда | Что делает |
|---------|-----------|
| `/pplan N` | Планирование: анализ задачи, декомпозиция, создание чеклиста |
| `/work N` | Реализация: написание кода по чеклисту |
| `/verify N` | Проверка: тесты, линтинг, guardrails (секреты, миграции) |
| `/ship N` | Слияние: push ветки в `main` через `scripts/agent/ship.sh` |

### Guardrails

- `scripts/agent/check-secrets.sh` — запрещает коммит `.env`, токенов, ключей.
- `scripts/agent/check-migrations-append-only.sh` — запрещает изменение существующих миграций.
- `scripts/agent/ship.sh` — гейтит push: требует passing verify record для текущего HEAD.

## Тестирование

```bash
# API тесты (smoke + E2E)
cd api && python -m pytest tests/ -v

# Bot тесты
cd bot && python -m pytest tests/ -v

# Web сборка (проверка компиляции)
cd web && npm run build
```

## Запрещено без подтверждения

- Редактирование/удаление существующих миграций.
- Запуск миграций на живой БД без бэкапа.
- Коммит `.env`, токенов, ключей, `.db`, логов.
- Изменение файлов вне скоупа текущего тикета.
