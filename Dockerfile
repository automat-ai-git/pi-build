FROM ubuntu:24.04

USER root

RUN apt-get update && apt-get install -y \
    curl \
    git \
    ripgrep \
    fd-find \
    ttyd \
    procps \
    nano \
    jq \
    docker.io \
    locales \
    fonts-liberation \
    fonts-dejavu-core \
    sudo \
    python3-pip \
    libevent-dev libncurses-dev build-essential bison pkg-config \
    && curl -fsSL https://deb.nodesource.com/setup_24.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && sed -i '/ru_RU.UTF-8/s/^# //g' /etc/locale.gen \
    && locale-gen

# tmux из исходников (Ubuntu 24.04 даёт только 3.4; extended-keys требует 3.5+).
# Версия на копирование не влияет — 3.5a и 3.8 ведут себя одинаково
RUN curl -fsSL https://github.com/tmux/tmux/releases/download/3.8/tmux-3.8.tar.gz | tar xz \
    && cd tmux-3.8 && ./configure && make -j$(nproc) && make install \
    && cd .. && rm -rf tmux-3.8

# ttyd frontend с поддержкой OSC52 (буфер обмена браузера)
# apt-версия ttyd (1.7.x) не имеет @xterm/addon-clipboard,
# поэтому собираем фронтенд из main ветки и подаём через -I.
# + патч ttyd#1565: браузер молча отбрасывает navigator.clipboard.writeText()
# без user activation, а OSC52 прилетает по WebSocket без клика. Патч
# регистрирует обработчик OSC52 через document.execCommand('copy') —
# копирование мышью работает без жеста и на обычном http (PR не влит в upstream)
RUN git clone --depth 1 https://github.com/tsl0922/ttyd.git /tmp/ttyd-src \
    && cd /tmp/ttyd-src \
    && curl -fsSL https://patch-diff.githubusercontent.com/raw/tsl0922/ttyd/pull/1565.diff | git apply \
    && sed -i 's|const text = atob(args\[1\]);|const text = new TextDecoder().decode(Uint8Array.from(atob(args[1]), (c) => c.charCodeAt(0)));|' html/src/components/terminal/xterm/index.ts \
    && cd html \
    && corepack enable \
    && corepack prepare yarn@3.6.3 --activate \
    && yarn install \
    && yarn build \
    && npx gulp inline \
    && cp dist/inline.html /usr/share/ttyd-index.html \
    && cd / && rm -rf /tmp/ttyd-src

# Docker Compose plugin (agent manages compose stacks via docker.sock)
RUN mkdir -p /usr/local/lib/docker/cli-plugins && \
    curl -SL "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-$(uname -m)" \
    -o /usr/local/lib/docker/cli-plugins/docker-compose && \
    chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

ENV LANG=ru_RU.UTF-8
ENV LC_ALL=ru_RU.UTF-8

RUN groupadd -g 2000 workspace_users && \
    useradd -u 1002 -g 2000 -m -s /bin/bash pi && \
    echo "pi ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/pi && \
    chmod 0440 /etc/sudoers.d/pi

# Pi coding agent (--ignore-scripts per official docs)
RUN npm install -g --ignore-scripts @earendil-works/pi-coding-agent

# fd-find ставится как fdfind, Pi ищет fd
RUN ln -s /usr/bin/fdfind /usr/local/bin/fd

# Graphify — скилл для Pi (knowledge graph queries)
RUN pip3 install --break-system-packages graphifyy

COPY yank /usr/local/bin/yank
RUN chmod +x /usr/local/bin/yank

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

COPY tmux.conf /home/pi/.tmux.conf
RUN chown pi:workspace_users /home/pi/.tmux.conf

# Defaults (copied to volume on first run by entrypoint)
RUN mkdir -p /home/pi/.pi-defaults
COPY models.json.example /home/pi/.pi-defaults/models.json
COPY settings.json.example /home/pi/.pi-defaults/settings.json
RUN chown -R pi:workspace_users /home/pi/.pi-defaults

# Баннер при входе в bash
RUN cat > /home/pi/.pi-banner << 'BANNER'

  ══════════════════════════════════════
  π  Pi Coding Agent (llama.cpp)
  ══════════════════════════════════════
  Копировать:  выделить мышью, отпустить
  В сессии:    Shift + выделить, отпустить
  Вставить:    правый клик > Paste / Ctrl+Shift+V
  ──────────────────────────────────────
  tmux: Ctrl+B, C  — новое окно
        Ctrl+B, N  — следующее окно
        Ctrl+B, D  — отсоединиться
  ══════════════════════════════════════

BANNER
RUN chown pi:workspace_users /home/pi/.pi-banner && \
    grep -q 'pi-banner' /home/pi/.bashrc 2>/dev/null || \
    echo 'cat ~/.pi-banner 2>/dev/null' >> /home/pi/.bashrc && \
    chown pi:workspace_users /home/pi/.bashrc

USER pi
WORKDIR /workspace
ENTRYPOINT ["/entrypoint.sh"]
