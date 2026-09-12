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

### Проблема со вставкой (правый клик открывает панель сбоку)

**Симптом:** внутри агента по правому клику появляются два меню (браузера и
tmux), а при попытке «Вставить» вместо вставки сбоку открывается вторая панель.

**Причина:** включена мышь (`set -g mouse on`), и tmux 3.3+ сам перехватывает
правый клик (`MouseDown3Pane`), рисуя своё контекстное меню. Клик по «Вставить»
попадает в это меню и срабатывает разбиение панели (`split-window`).

**Быстрый обход (без правок):**
- `Shift` + правый клик — Shift не отдаёт клик мыши в tmux, остаётся только меню браузера;
- `Ctrl+Shift+V` — вставка с клавиатуры, мышь не участвует.

**Постоянное решение** — убрать перехват правого клика у tmux (колёсико-скролл
сохраняется). Добавить в `tmux.conf` после `set -g mouse on`:

```tmux
# Не перехватывать правый клик — пусть работает вставка из браузера
unbind -n MouseDown3Pane
unbind -n MouseDown3Status
unbind -n MouseDown3StatusLeft
```

Применить на живую (без пересборки):

```bash
docker cp tmux.conf <контейнер>:/home/pi/.tmux.conf \
  && docker exec -u pi <контейнер> tmux source-file /home/pi/.tmux.conf
```

Чтобы закрепить — правка `tmux.conf` + пересборка образа (`--build`).

## Caddy (опционально)

Скопировать `caddy-addon/site-pi.conf` в конфиг Caddy для доступа через домен с basic auth.
