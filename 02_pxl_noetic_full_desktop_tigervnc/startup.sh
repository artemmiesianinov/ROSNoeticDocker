#!/bin/bash
set -euo pipefail

: "${VNC_PASSWORD:=1234}"
: "${VNC_GEOMETRY:=1920x1080}"
: "${VNC_DEPTH:=24}"
: "${DISPLAY:=:1}"

# Clean old session/locks
vncserver -kill "$DISPLAY" >/dev/null 2>&1 || true
rm -f "/tmp/.X${DISPLAY#:}-lock" "/tmp/.X11-unix/X${DISPLAY#:}" 2>/dev/null || true

# Ensure VNC password exists
mkdir -p "$HOME/.vnc"
if [ ! -f "$HOME/.vnc/passwd" ]; then
  echo "$VNC_PASSWORD" | vncpasswd -f > "$HOME/.vnc/passwd"
  chmod 600 "$HOME/.vnc/passwd"
fi

# Avoid xrdb crash
touch "$HOME/.Xresources"

# Create xstartup only if missing (auto-restart XFCE)
if [ ! -f "$HOME/.vnc/xstartup" ]; then
  cat > "$HOME/.vnc/xstartup" <<'EOF'
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
xrdb -merge "$HOME/.Xresources"

while true; do
  if command -v dbus-launch >/dev/null 2>&1; then
    dbus-launch --exit-with-session startxfce4
  else
    startxfce4
  fi
  echo "XFCE session ended; restarting in 2s..." >&2
  sleep 2
done
EOF
  chmod +x "$HOME/.vnc/xstartup"
fi

# Default VNC server config
if [ ! -f "$HOME/.vnc/config" ]; then
  cat > "$HOME/.vnc/config" <<'EOF'
geometry=1920x1080
depth=24
localhost=no
AlwaysShared
DisconnectClients=0
SecurityTypes=VNCAuth
EOF
fi

# Start VNC (daemonizes, runs xstartup, logs under ~/.vnc/<host>:1.log)
export DISPLAY
vncserver "$DISPLAY" -geometry "$VNC_GEOMETRY" -depth "$VNC_DEPTH" -localhost no

LOGFILE="$HOME/.vnc/$(hostname)${DISPLAY}.log"
[ -f "$LOGFILE" ] || touch "$LOGFILE"
exec tail -F "$LOGFILE"
