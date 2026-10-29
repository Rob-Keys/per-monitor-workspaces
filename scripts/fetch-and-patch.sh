#!/bin/sh
set -eu

repo=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
source_root=${1:-"$repo/work/sources"}
mkdir -p "$source_root"

clone_at() {
  name=$1
  url=$2
  ref=$3
  commit=$4
  patch=$5
  path="$source_root/$name"
  if [ ! -d "$path/.git" ]; then
    git clone --filter=blob:none --depth=1 --no-checkout --single-branch "$url" "$path"
  fi
  actual=$(git -C "$path" rev-parse HEAD 2>/dev/null || true)
  if [ "$actual" != "$commit" ]; then
    git -C "$path" fetch --depth=1 origin "$ref"
    git -C "$path" checkout --detach "$commit"
  fi
  actual=$(git -C "$path" rev-parse HEAD)
  if [ "$actual" != "$commit" ]; then
    echo "$name checkout is $actual; expected pinned commit $commit." >&2
    exit 1
  fi
  if git -C "$path" apply --check "$repo/patches/$patch" 2>/dev/null; then
    git -C "$path" apply "$repo/patches/$patch"
  elif git -C "$path" apply --reverse --check "$repo/patches/$patch" 2>/dev/null; then
    printf '%s\n' "$name patch is already applied"
  else
    echo "Patch does not match $name at $commit; use a clean checkout." >&2
    exit 1
  fi
}

clone_at mutter https://github.com/GNOME/mutter.git refs/tags/46.2 \
  02050414855b370dbf2b08a971c8b332f7b3c9f4 0001-mutter-per-monitor-workspaces.patch
clone_at gnome-shell https://github.com/GNOME/gnome-shell.git \
  refs/tags/46.0 0463511457612ca87f7426b3b01356d1d85bee9b 0002-gnome-shell-per-monitor-workspaces.patch
clone_at smart-workspace-manager https://github.com/devops-dude-dinodam/smart-workspace-manager.git \
  refs/heads/master a4fa366445608f6d865461d289507dbd08e2fd65 0003-smart-workspace-manager-compat.patch
printf 'Patched sources are in %s\n' "$source_root"
