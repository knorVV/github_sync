# GitHub Sync Service (Elixir)

Сервис для синхронизации трендовых репозиториев GitHub.
Elixir-версия [Go-реализации](https://github.com/knorVV/github_sync_go).

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Elixir](https://img.shields.io/badge/Elixir-1.11%2B-purple.svg)](https://elixir-lang.org)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-required-blue.svg)](https://www.postgresql.org)
[![Plug](https://img.shields.io/badge/Plug-Router-green.svg)](https://hex.pm/packages/plug)
[![Status: Experimental](https://img.shields.io/badge/status-experimental-red.svg)](#статус-проекта)

> ⚠️ **Экспериментальный проект.** Не продакшн-код.

## Что делает

- Периодически запрашивает GitHub Search API
- Отбирает репозитории, созданные за последние 7 дней
- Сортирует по звёздам, сохраняет в PostgreSQL
- Отдаёт данные через HTTP API
- Предоставляет CLI для работы с сервисом

## Стек

- **Elixir** ~> 1.x
- **Plug** — HTTP-роутер (лёгкий, без Phoenix)
- **Req** — HTTP-клиент для GitHub API
- **Ecto + PostgreSQL** — хранение репозиториев
- **escript** — сборка CLI

## Архитектура

```
lib/
├── github_sync/
│   ├── application.ex
│   ├── github_client.ex      # клиент GitHub Search API
│   ├── scheduler.ex          # планировщик (GenServer)
│   └── repo_stores.ex        # работа с PostgreSQL (Ecto)
├── github_sync_web/
│   ├── router.ex             # Plug.Router
│   └── repo_controller.ex    # хендлеры
└── github_sync/
    └── cli.ex                # CLI-клиент (escript)
```

## GitHub API

Официального `/trending` endpoint у GitHub нет, поэтому используется
Search API с фильтром по дате создания:

```
GET https://api.github.com/search/repositories
  ?q=created:>{дата 7 дней назад}
  &sort=stars
  &order=desc
  &per_page=30
```

**Аутентификация (опционально):** токен передаётся через конфиг
(`:github_sync, :github_token`). Без токена работает, но с меньшим
rate limit (60 запросов/час вместо 5000).

**Обработка ошибок:**

| Статус | Что означает | Что делает клиент |
|---|---|---|
| 200 | OK | Нормализует и возвращает список |
| 403 | Rate limit | Парсит `x-ratelimit-*` из заголовков |
| 422 | Unprocessable | Возвращает тело ошибки |
| Другое | Ошибка GitHub | Общая ошибка |
| — | HTTP-ошибка | `{:error, {:http_error, reason}}` |

## Планировщик

Реализован как `GenServer` без cron и без внешних зависимостей.

- При старте сразу запускает первую синхронизацию
- После каждой синхронизации планирует следующую через `Process.send_after`
- Интервал по умолчанию — 5 минут (настраивается через `opts`)
- `force_sync/0` отменяет текущий таймер (`Process.cancel_timer`) и
  запускает синхронизацию немедленно, после чего ставит новый таймер
  на полный интервал

Прямой аналог Go-версии, где используется `time.Timer` + `time.AfterFunc`
и `timer.Stop()` при ForceSync.

## API

| Метод | Путь | Описание |
|---|---|---|
| GET | `/api/repos` | Все репозитории, сортировка по звёздам |
| GET | `/api/repos/:id` | По GitHub ID, имени или full_name |
| POST | `/api/sync` | Принудительная синхронизация (202 Accepted, сбрасывает таймер) |

**Примеры:**

```bash
# Список репозиториев
curl http://localhost:4000/api/repos

# Конкретный репозиторий
curl http://localhost:4000/api/repos/elixir-lang

# Форсировать синхронизацию
curl -X POST http://localhost:4000/api/sync
```

## CLI

Собирается в escript:

```bash
mix escript.build
```

Использование:

```bash
./github_sync_cli list          # список (топ-20 по звёздам)
./github_sync_cli get <name>    # по имени, full_name или GitHub ID
./github_sync_cli sync          # форсировать синхронизацию
```

CLI обращается к серверу через HTTP (`cli_base_url`, по умолчанию
`http://localhost:4000`).

## Запуск

### 1. Поднять PostgreSQL

```bash
docker compose up -d
```

### 2. Установить зависимости и применить миграции

```bash
mix deps.get
mix ecto.setup
```

### 3. Запустить сервер

```bash
mix run --no-halt
```

### 4. Проверить

```bash
curl http://localhost:4000/api/repos
```

## Сравнение с Go-версией

Один и тот же сервис реализован на двух языках:

| | [github_sync_go](https://github.com/knorVV/github_sync_go) | github_sync (этот) |
|---|---|---|
| Язык | Go 1.27 | Elixir |
| HTTP-роутер | chi | Plug.Router |
| HTTP-клиент | net/http | Req |
| БД | pgx (pgxpool + batch upsert) | Ecto |
| Планировщик | time.Timer + time.AfterFunc | GenServer + Process.send_after |
| CLI | cmd/cli | escript |

Проект — упражнение в сравнении подходов: как одни и те же задачи
решаются в разных экосистемах. В Elixir-версии сознательно **не используется
Phoenix** — для трёх эндпоинтов достаточно `Plug.Router`, это меньше
зависимостей и быстрее компиляция.

## Статус проекта

Экспериментальный проект. Создан для сравнения подходов Go и Elixir
к одной и той же задаче.

Не предназначен для продакшн-использования.

## Лицензия

Распространяется под лицензией MIT. Полный текст — в файле [LICENSE](LICENSE).

Copyright (c) 2026 knorVV