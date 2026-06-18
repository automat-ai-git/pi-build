# Pi Coding Agent — Docker Build

Контейнеризированный [Pi](https://pi.dev) coding agent с веб-терминалом (ttyd + tmux).

## Быстрый старт

```bash
cp .env.example .env
# Заполнить ANTHROPIC_API_KEY в .env

docker compose -f docker-compose.pi.yml up --build -d
```

Открыть: http://localhost:7683

## Что внутри

- **Pi** — AI coding agent от Earendil Works
- **tmux** — параллельные сессии Pi в одном терминале
- **ttyd** — веб-доступ к tmux через браузер
- **Docker-in-Docker** — Pi может создавать контейнеры

## tmux

Каждое подключение через браузер аттачится к общей tmux-сессии `main`.
Можно открывать новые окна (`Ctrl+B, C`) и запускать несколько Pi параллельно.

## Caddy (опционально)

Скопировать `caddy-addon/site-pi.conf` в конфиг Caddy для доступа через домен с basic auth.
