#!/bin/sh
set -eu

prefix=/opt/per-monitor-workspaces/usr
install_user=${INSTALL_USER:-${SUDO_USER:-}}
if [ "$(id -u)" -ne 0 ]; then
  echo 'Run this uninstaller with sudo.' >&2
  exit 1
fi
if [ -z "$install_user" ] || [ "$install_user" = root ]; then
  echo 'Set INSTALL_USER or run through sudo from the target user account.' >&2
  exit 1
fi
user_home=$(getent passwd "$install_user" | cut -d: -f6)
uid=$(id -u "$install_user")
rm -f /usr/share/wayland-sessions/ubuntu-per-monitor-workspaces.desktop
rm -f /usr/local/bin/gnome-shell-per-monitor-session
rm -rf /opt/per-monitor-workspaces/usr
rm -f "$user_home/.config/systemd/user/gnome-session@ubuntu-per-monitor-workspaces.target.d/session.conf"
rm -f "$user_home/.config/systemd/user/org.gnome.Shell.PerMonitor.service"
rm -f "$user_home/.config/gnome-session/sessions/ubuntu-per-monitor-workspaces.session"
rm -f "$user_home/.local/share/applications/org.gnome.Shell.PerMonitor.desktop"
if [ -S "/run/user/$uid/bus" ]; then
  runuser -u "$install_user" -- env XDG_RUNTIME_DIR="/run/user/$uid" \
    DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$uid/bus" systemctl --user daemon-reload
fi
printf 'Removed the per-monitor session for %s. The standard Ubuntu session remains available.\n' "$install_user"
