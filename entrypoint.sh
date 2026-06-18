#!/bin/bash
set -e

# Первый запуск: volume пуст — скопировать дефолтные конфиги
mkdir -p /home/pi/.pi/agent
if [ ! -f /home/pi/.pi/agent/models.json ]; then
    cp /home/pi/.pi-defaults/models.json /home/pi/.pi/agent/models.json
fi
chown -R pi:workspace_users /home/pi/.pi

# Баннер при входе в bash
cat > /home/pi/.pi-banner << 'BANNER'

  ══════════════════════════════════════
  π  Pi Coding Agent (llama.cpp)
  ══════════════════════════════════════
  tmux: Ctrl+B, C  — новое окно
         Ctrl+B, N — следующее окно
         Ctrl+B, D — отсоединиться
  ══════════════════════════════════════

BANNER
chown pi:workspace_users /home/pi/.pi-banner

# Добавить баннер в .bashrc если ещё нет
grep -q 'pi-banner' /home/pi/.bashrc 2>/dev/null || \
    echo 'cat ~/.pi-banner 2>/dev/null' >> /home/pi/.bashrc

# ttyd → tmux: каждое подключение аттачится к сессии "main".
# При первом старте tmux автоматически запускает Pi с llama.cpp.
exec runuser -u pi -- env \
    HOME=/home/pi \
    PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
    ttyd -p 7681 -W \
    bash -c '
        if tmux has-session -t main 2>/dev/null; then
            tmux attach-session -t main
        else
            tmux new-session -d -s main -c /workspace
            tmux send-keys -t main "pi --provider llama-cpp --model qwen || echo Набери pi чтобы запустить снова" Enter
            tmux attach-session -t main
        fi
    '
