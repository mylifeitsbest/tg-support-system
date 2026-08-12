# TG Support System

Асинхронная система поддержки пользователей Telegram.
Пользователь пишет боту — оператор отвечает через Telegram Mini App.

## Архитектура

```
┌──────────┐   Telegram API   ┌──────────┐  HTTP :8000  ┌──────────┐
│  Клиент  │ ◄──────────────► │   Bot    │ ◄──────────► │   API    │
│ Telegram │                  │ aiogram  │              │ FastAPI  │
└──────────┘                  │  :8001   │              │ SQLite   │
                              └──────────┘              └────┬─────┘
                                                             │
                                                     initData auth
                                                             │
                                                       ┌─────▼─────┐
                                                       │  MiniApp  │
                                                       │  Vue 3    │
                                                       │  :5173    │
                                                       └───────────┘
```

### Цикл сообщения

1. **Пользователь** → Telegram → **Bot** (`/start` создает чат, текст → `POST /chats/{id}/messages`)
2. **Оператор** открывает Mini App → `GET /chats` (список) → `POST /chats/{id}/claim` (берет в работу)
3. **Оператор** пишет ответ → `POST /chats/{id}/messages` (sender=operator) → API отправляет `POST http://bot:8001/send` → бот пересылает пользователю

### Сервисы

| Сервис | Стек | Порт | Запуск |
|--------|------|------|--------|
| `api/` | FastAPI + SQLAlchemy + SQLite | 8000 | `make api` |
| `bot/` | aiogram 3 + aiohttp callback | 8001 | `make bot` |
| `web/` | Vue 3 + Tailwind CSS (Mini App) | 5173 | `make web` |

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

### 3. Применить миграции

```bash
cd api && alembic upgrade head
```

### 4. Запустить все сервисы

```bash
make dev     # запускает api + bot + web параллельно
```

Или по отдельности:

```bash
make api     # uvicorn на :8000
make bot     # aiogram polling + aiohttp на :8001
make web     # vite dev на :5173
```

### 5. Docker

```bash
make docker-up    # docker compose up --build
make docker-down  # docker compose down
```

## Переменные окружения

| Переменная | Сервис | Описание | По умолчанию |
|---|---|---|---|
| `BOT_TOKEN` | api, bot | Токен от @BotFather | — (обязательно) |
| `OPERATOR_ALLOWLIST` | api | Telegram user_id операторов через запятую | `""` |
| `DATABASE_URL` | api | SQLite URL | `sqlite+aiosqlite:///./support.db` |
| `BOT_CALLBACK_URL` | api | URL callback-сервера бота | `http://localhost:8001/send` |
| `API_BASE_URL` | bot | URL API | `http://localhost:8000` |
| `VITE_API_BASE_URL` | web | URL API для фронтенда | `http://localhost:8000` |

## Аутентификация

### Оператор (MiniApp → API)
Mini App передает `Authorization: tma <initData>` с каждым запросом.
API валидирует HMAC-SHA256 подпись (ключ — `BOT_TOKEN`) и проверяет `user.id` ∈ `OPERATOR_ALLOWLIST`.

### Бот → API
Бот вызывает API-эндпоинты напрямую без авторизации (внутренняя сеть).
Эндпоинты `/users`, `/chats` (POST), `/chats/{id}/messages` (POST) не требуют auth.

### API → Бот (callback)
При отправке оператором сообщения API делает `POST` на `BOT_CALLBACK_URL`
с телом `{"chat_id": <tg_user_id>, "text": "<message>"}`.

## Claim / Lock механика

- `POST /chats/{id}/claim` — оператор берет чат в работу.
- Если чат уже взят другим оператором → `409 Conflict`.
- Повторный claim тем же оператором — идемпотентен (возвращает `200`).
- `PATCH /chats/{id}/status` — смена статуса: `open` → `in_progress` → `closed`.

## API-эндпоинты

| Метод | Путь | Auth | Описание |
|-------|------|------|----------|
| GET | `/health` | — | Health check |
| POST | `/users` | — | Регистрация/обновление пользователя |
| GET | `/chats` | operator | Список всех чатов |
| POST | `/chats` | — | Создание чата (бот) |
| POST | `/chats/{id}/claim` | operator | Взять чат в работу |
| PATCH | `/chats/{id}/status` | operator | Сменить статус чата |
| GET | `/chats/{id}/messages` | operator | История сообщений |
| POST | `/chats/{id}/messages` | — | Отправить сообщение |

## Тесты

```bash
make test           # все тесты API (smoke + E2E)
cd bot && pytest    # тесты бота
```

### Покрытие

- **Smoke-тесты** (`test_routes.py`): 9 тестов — CRUD users/chats/messages, auth, claim/conflict
- **E2E** (`test_e2e.py`): 3 теста — полный цикл user→operator→user, race condition claim, reply без claim
- **Bot** (`test_handlers.py`): 3 теста — /start, сообщение без чата, пересылка сообщения

## Структура проекта

```
tg-support-system/
├── api/
│   ├── alembic/              # Миграции БД
│   ├── app/
│   │   ├── auth.py           # HMAC-валидация initData
│   │   ├── config.py         # Настройки (pydantic-settings)
│   │   ├── database.py       # Async SQLAlchemy engine
│   │   ├── main.py           # FastAPI app
│   │   ├── models.py         # ORM-модели (TgUser, Chat, Message)
│   │   ├── routes.py         # REST-эндпоинты + bot callback
│   │   └── schemas.py        # Pydantic-схемы
│   └── tests/
│       ├── test_routes.py    # Smoke-тесты
│       └── test_e2e.py       # E2E интеграция
├── bot/
│   ├── app/
│   │   ├── api_client.py     # HTTP-клиент к API
│   │   ├── config.py         # Настройки бота
│   │   ├── handlers.py       # Aiogram хэндлеры
│   │   ├── main.py           # Точка входа (polling + aiohttp :8001)
│   │   └── storage.py        # In-memory user→chat mapping
│   └── tests/
│       └── test_handlers.py  # Smoke-тесты хэндлеров
├── web/
│   ├── src/
│   │   ├── api.js            # API-клиент с initData auth
│   │   ├── main.js           # Vue app + router
│   │   ├── style.css         # Glassmorphism design system
│   │   └── views/
│   │       ├── ChatList.vue  # Список обращений
│   │       └── ChatView.vue  # Чат-интерфейс
│   └── index.html            # Telegram WebApp SDK
├── .env.example
├── docker-compose.yml
├── Makefile
└── CONTRIBUTING.md
```

## Агентский воркфлоу

```
/pplan N → /work N → /verify N → /ship N
```

Подробнее: [`CONTRIBUTING.md`](CONTRIBUTING.md)
