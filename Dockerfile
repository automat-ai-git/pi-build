FROM node:24-bookworm-slim

USER root

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    curl \
    git \
    ripgrep \
    tmux \
    ttyd \
    procps \
    nano \
    jq \
    docker.io \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd -g 2000 workspace_users && \
    useradd -u 1002 -g 2000 -m -s /bin/bash pi

# Pi coding agent (--ignore-scripts per official docs)
RUN npm install -g --ignore-scripts @earendil-works/pi-coding-agent

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

COPY tmux.conf /home/pi/.tmux.conf
RUN chown pi:workspace_users /home/pi/.tmux.conf

WORKDIR /workspace
ENTRYPOINT ["/entrypoint.sh"]
