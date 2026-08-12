# TG Support System

Асинхронная система поддержки пользователей Telegram.
Пользователь пишет боту — оператор отвечает через Telegram Mini App.

## Архитектура

```
tg-support-system/
├── api/    # FastAPI + SQLAlchemy + SQLite  →  :8000
├── bot/    # aiogram 3 (polling)
└── web/    # Vue 3 + Tailwind (Telegram Mini App)  →  :5173
```

Цикл сообщения:
```
Пользователь → Telegram → Bot → POST /chats/{id}/messages
Оператор (MiniApp) → GET /chats  →  POST /chats/{id}/messages
                    → API отправляет ответ пользователю (через bot webhook или polling)
```

## Требования

- Python 3.11+
- Node.js 20+
- [GitHub CLI](https://cli.github.com/) (`gh`) — для агентского воркфлоу

## Быстрый старт

### 1. Переменные окружения

```bash
cp .env.example .env
# Отредактировать .env: вписать BOT_TOKEN, OPERATOR_ALLOWLIST
```

### 2. Установить зависимости

```bash
make install
```

### 3. Запустить все сервисы

```bash
make dev     # запускает api + bot + web параллельно
```

Или по отдельности:

```bash
make api     # uvicorn на :8000
make bot     # aiogram polling
make web     # vite dev на :5173
```

### 4. Docker

```bash
make docker-up    # docker compose up --build
make docker-down  # docker compose down
```

## Переменные окружения

| Переменная | Где используется | Описание |
|---|---|---|
| `BOT_TOKEN` | api, bot | Токен от @BotFather |
| `OPERATOR_ALLOWLIST` | api | Telegram user_id операторов через запятую |
| `DATABASE_URL` | api | SQLite URL (default: `sqlite+aiosqlite:///./support.db`) |
| `API_BASE_URL` | bot | URL API (default: `http://localhost:8000`) |
| `VITE_API_BASE_URL` | web | URL API для фронтенда (default: `http://localhost:8000`) |

## Аутентификация оператора

Mini App передаёт `Authorization: tma <initData>` с каждым запросом.
API валидирует HMAC-SHA256 подпись и проверяет `user.id` в `OPERATOR_ALLOWLIST`.

## Тесты

```bash
make test    # cd api && pytest
```

## Агентский воркфлоу

```
/pplan N → /work N → /verify N → /ship N
```

Подробнее: [`docs/agent-workflow.md`](docs/agent-workflow.md)
