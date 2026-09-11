# Pi Coding Agent — Docker Build

Контейнеризированный [Pi](https://pi.dev) coding agent с веб-терминалом (ttyd + tmux).

## Быстрый старт

```bash
cp .env.example .env
# Заполнить ANTHROPIC_API_KEY и HOST_HOME в .env
# HOST_HOME — абсолютный путь к домашней папке на хосте, без завершающего слэша:
echo "HOST_HOME=$HOME" >> .env
echo "DOCKER_GID=$(stat -c '%g' /var/run/docker.sock)" >> .env

# Папки, которые монтируются в контейнер (чтобы Docker не создал их от root)
mkdir -p ~/workspace ~/pi-build/agent

cp models.json.example models.json
cp settings.json.example settings.json
# Отредактировать под свою машину (провайдеры, модели, URL-ы)

docker compose -f docker-compose.pi.yml up --build -d
```

Открыть: http://localhost:7683

> **Важно:** файл `.env` в `.gitignore` и не приезжает с `git clone`/`git pull`.
> На каждой новой машине его нужно создать заново. Если `HOST_HOME` не задан,
> `docker compose` упадёт с понятным сообщением (а не с `invalid spec: :/host`).
> Проверить, что переменные подхватились:
> `docker compose -f docker-compose.pi.yml config | grep -A2 volumes`

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
