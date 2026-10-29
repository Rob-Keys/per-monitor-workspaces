#!/bin/sh
set -eu

runtime=${1:?Usage: prepare-runtime.sh RUNTIME_DIR}
patch_tool=${PATCHELF:-patchelf}
multiarch=$(dpkg-architecture -qDEB_HOST_MULTIARCH)

if [ -d /usr/share/gnome-shell/theme/Yaru ]; then
  mkdir -p "$runtime/share/gnome-shell/theme"
  cp -a /usr/share/gnome-shell/theme/Yaru "$runtime/share/gnome-shell/theme/"
else
  echo 'Ubuntu Yaru theme resources are required for the Ubuntu session.' >&2
  exit 1
fi

# GNOME Shell prepends $ORIGIN paths from its RUNPATH to introspection lookup.
# This keeps GI from loading an installed system copy beside the staged library.
"$patch_tool" --set-rpath \
  "\$ORIGIN/../lib/$multiarch/mutter-14:\$ORIGIN/../lib/$multiarch/gnome-shell:\$ORIGIN/../lib/$multiarch" \
  "$runtime/bin/gnome-shell"
