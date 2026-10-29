#!/bin/sh
set -eu

repo=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
prefix=/opt/per-monitor-workspaces/usr
multiarch=$(dpkg-architecture -qDEB_HOST_MULTIARCH)
install_user=${INSTALL_USER:-${SUDO_USER:-}}

if [ "$(id -u)" -ne 0 ]; then
  echo 'Run this installer with sudo.' >&2
  exit 1
fi
if [ -z "$install_user" ] || [ "$install_user" = root ]; then
  echo 'Set INSTALL_USER or run through sudo from the target user account.' >&2
  exit 1
fi
user_record=$(getent passwd "$install_user") || exit 1
user_home=$(printf '%s\n' "$user_record" | cut -d: -f6)
user_group=$(id -gn "$install_user")
uid=$(id -u "$install_user")
source_runtime=${RUNTIME_DIR:-"$repo/build/rootfs$prefix"}

if [ ! -x "$source_runtime/bin/gnome-shell" ]; then
  echo "Built runtime missing at $source_runtime. Run scripts/build.sh first." >&2
  exit 1
fi
if ! readelf -d "$source_runtime/bin/gnome-shell" | grep -Fq '$ORIGIN/../lib/'; then
  echo 'Runtime is missing relocatable introspection paths; rebuild it first.' >&2
  exit 1
fi
if [ ! -r "$source_runtime/share/gnome-shell/theme/Yaru/gnome-shell-theme.gresource" ]; then
  echo 'Ubuntu Yaru theme resources are missing; rebuild it first.' >&2
  exit 1
fi

# This tree is owned by this app; replace its contents on upgrades.
install -d -m 0755 /opt/per-monitor-workspaces
rm -rf /opt/per-monitor-workspaces/usr
cp -a "$source_runtime" /opt/per-monitor-workspaces/usr
chmod -R a+rX /opt/per-monitor-workspaces/usr
install -D -m 0755 "$repo/packaging/gnome-shell-per-monitor-session" /usr/local/bin/gnome-shell-per-monitor-session
install -D -m 0644 "$repo/packaging/ubuntu-per-monitor-workspaces.desktop" /usr/share/wayland-sessions/ubuntu-per-monitor-workspaces.desktop

user_config="$user_home/.config/systemd/user"
session_config="$user_home/.config/gnome-session/sessions"
user_data="$user_home/.local/share"
install -d -o "$install_user" -g "$user_group" -m 0755 \
  "$user_config/gnome-session@ubuntu-per-monitor-workspaces.target.d" \
  "$session_config" "$user_data/applications"
service_tmp=$(mktemp)
trap 'rm -f "$service_tmp"' EXIT HUP INT TERM
sed "s/@MULTIARCH@/$multiarch/g" "$repo/packaging/org.gnome.Shell.PerMonitor.service" > "$service_tmp"
install -o "$install_user" -g "$user_group" -m 0644 "$service_tmp" "$user_config/org.gnome.Shell.PerMonitor.service"
