#!/bin/bash
set -e

chown -R pi:workspace_users /home/pi/.pi 2>/dev/null || true

cat > /etc/pi-init << 'EOF'
[ -f ~/.bashrc ] && source ~/.bashrc

echo ""
echo "  ══════════════════════════════════════"
echo "  π  Pi Coding Agent"
echo "  ══════════════════════════════════════"
echo "  pi                — запустить сессию"
echo "  pi -c             — продолжить последнюю"
echo "  pi -r             — выбрать из прошлых"
echo "  pi --help         — все команды"
echo "  ──────────────────────────────────────"
echo "  tmux: Ctrl+B, C  — новое окно"
echo "         Ctrl+B, N — следующее окно"
echo "         Ctrl+B, D — отсоединиться"
echo "  ══════════════════════════════════════"
echo ""
EOF

# ttyd → tmux: каждое подключение через браузер аттачится к общей
# tmux-сессии "main", либо создаёт новую если её нет.
# Это позволяет запускать несколько pi параллельно в разных окнах tmux.
exec runuser -u pi -- env \
    HOME=/home/pi \
    PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
    ttyd -p 7681 -W \
    tmux new-session -A -s main -c /workspace
