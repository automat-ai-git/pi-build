#!/bin/bash
set -e

# Дать пользователю pi доступ к docker.sock
if [ -S /var/run/docker.sock ]; then
    HOST_DOCKER_GID=$(stat -c '%g' /var/run/docker.sock)
    if ! getent group "$HOST_DOCKER_GID" >/dev/null; then
        sudo groupadd -g "$HOST_DOCKER_GID" dockerhost
    fi
    sudo usermod -aG "$HOST_DOCKER_GID" pi
fi

# Первый запуск: volume пуст — скопировать дефолтные конфиги
mkdir -p /home/pi/.pi/agent
if [ ! -f /home/pi/.pi/agent/models.json ]; then
    cp /home/pi/.pi-defaults/models.json /home/pi/.pi/agent/models.json
fi
if [ ! -f /home/pi/.pi/agent/settings.json ]; then
    cp /home/pi/.pi-defaults/settings.json /home/pi/.pi/agent/settings.json
fi
sudo chown -R pi:workspace_users /home/pi/.pi

# ttyd → tmux: каждое подключение аттачится к сессии "main".
exec ttyd -p 7681 -W -I /usr/share/ttyd-index.html \
    bash -c 'tmux attach -d || tmux new -s main -c /workspace'
