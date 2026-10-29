#!/bin/sh
set -eu

repo=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
source_root=${1:-"$repo/work/sources"}
prefix=/opt/per-monitor-workspaces/usr
multiarch=$(dpkg-architecture -qDEB_HOST_MULTIARCH)
stage="$repo/build/rootfs"

for component in mutter gnome-shell; do
  if [ ! -d "$source_root/$component/.git" ]; then
    echo "Missing $component sources. Run scripts/fetch-and-patch.sh first." >&2
    exit 1
  fi
done
mkdir -p "$repo/build"

meson setup "$repo/build/mutter" "$source_root/mutter" \
  --prefix="$prefix" --libdir="lib/$multiarch" --buildtype=release \
  -Dtests=false -Dinstalled_tests=false -Ddocs=false -Dprofiler=false
ninja -C "$repo/build/mutter"
DESTDIR="$stage" ninja -C "$repo/build/mutter" install

export PKG_CONFIG_PATH="$stage$prefix/lib/$multiarch/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
meson setup "$repo/build/gnome-shell" "$source_root/gnome-shell" \
  --prefix="$prefix" --libdir="lib/$multiarch" --buildtype=release \
  -Dtests=false -Dman=false -Dnetworkmanager=false \
  -Dextensions_tool=false -Dextensions_app=false
ninja -C "$repo/build/gnome-shell"
DESTDIR="$stage" ninja -C "$repo/build/gnome-shell" install

runtime="$stage$prefix"
glib-compile-schemas "$runtime/share/glib-2.0/schemas"
"$repo/packaging/prepare-runtime.sh" "$runtime"
printf 'Built runtime in %s\n' "$runtime"
printf 'Install it with: sudo %s/packaging/install-login-session.sh\n' "$repo"
