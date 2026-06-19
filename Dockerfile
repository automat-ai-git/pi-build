FROM ubuntu:24.04

USER root

RUN apt-get update && apt-get install -y \
    curl \
    git \
    ripgrep \
    ttyd \
    procps \
    nano \
    jq \
    docker.io \
    locales \
    fonts-liberation \
    fonts-dejavu-core \
    libevent-dev libncurses-dev build-essential bison pkg-config \
    && curl -fsSL https://deb.nodesource.com/setup_24.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && sed -i '/ru_RU.UTF-8/s/^# //g' /etc/locale.gen \
    && locale-gen

# tmux 3.5a из исходников (Ubuntu 24.04 даёт только 3.4)
RUN curl -fsSL https://github.com/tmux/tmux/releases/download/3.5a/tmux-3.5a.tar.gz | tar xz \
    && cd tmux-3.5a && ./configure && make -j$(nproc) && make install \
    && cd .. && rm -rf tmux-3.5a

ENV LANG=ru_RU.UTF-8
ENV LC_ALL=ru_RU.UTF-8

RUN groupadd -g 2000 workspace_users && \
    useradd -u 1002 -g 2000 -m -s /bin/bash pi

# Pi coding agent (--ignore-scripts per official docs)
RUN npm install -g --ignore-scripts @earendil-works/pi-coding-agent

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

COPY tmux.conf /home/pi/.tmux.conf
RUN chown pi:workspace_users /home/pi/.tmux.conf

# Defaults (copied to volume on first run by entrypoint)
RUN mkdir -p /home/pi/.pi-defaults
COPY models.json /home/pi/.pi-defaults/models.json
RUN chown -R pi:workspace_users /home/pi/.pi-defaults

WORKDIR /workspace
ENTRYPOINT ["/entrypoint.sh"]
