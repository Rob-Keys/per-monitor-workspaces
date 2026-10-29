# Per-monitor workspaces for Ubuntu GNOME

This patch set gives each physical monitor its own active GNOME workspace.
Swiping on one monitor changes that monitor's workspace; windows on other
monitors remain mapped on their current workspaces. Workspace numbers come
from one shared dynamic list, while each monitor tracks its own current item.

It modifies Mutter's workspace manager and visibility rules, then updates GNOME
Shell's workspace animation to animate only the monitor receiving the gesture.
An optional compatibility patch makes Smart Workspace Manager skip its legacy
window migration while native per-monitor workspaces are enabled.

## Supported base

The patch series targets Ubuntu 24.04, GNOME Shell 46.0, Mutter 46.2, and
Wayland on amd64. See [patches/BASELINES.md](patches/BASELINES.md) for exact
upstream commit hashes. Other GNOME versions need a port and have not been
checked. The nested two-monitor check passes; physical DisplayLink gestures
still need confirmation on each target system.

## Build and install

Install Ubuntu's build dependencies. With `deb-src` repositories enabled, the
GNOME packages can supply their dependency list:

```sh
sudo apt build-dep mutter gnome-shell
sudo apt install git meson ninja-build pkg-config patchelf python3-dbus
```

Then fetch the pinned sources, apply the patches, and build into a staging tree:

```sh
git clone https://github.com/YOUR-NAME/per-monitor-workspaces.git
cd per-monitor-workspaces
./scripts/fetch-and-patch.sh
./scripts/build.sh
```

The builder installs into `build/rootfs/opt/per-monitor-workspaces/usr`; it does
not replace Ubuntu's Mutter or Shell packages. To register the separate login
session, install the staged files for the current account:

```sh
sudo ./packaging/install-login-session.sh
```

Log out and choose **Ubuntu (Per-Monitor Workspaces)** from GDM's session menu.
The regular Ubuntu session continues to use its distribution Shell service.
To remove this session and its private runtime, use:

```sh
sudo ./packaging/uninstall-login-session.sh
```

The installer sets Mutter's `per-monitor-workspaces` preference for the target
user. If installation ran without that user's session bus, run this after
logging in:

```sh
gsettings --schemadir /opt/per-monitor-workspaces/usr/share/glib-2.0/schemas \
  set org.gnome.mutter per-monitor-workspaces true
```

## Optional Smart Workspace Manager compatibility

The third patch targets the Smart Workspace Manager fork and makes it stand
down when Mutter's native mode is on. Apply it to the pinned extension source
created by `fetch-and-patch.sh`, then install the extension for your user:

```sh
mkdir -p ~/.local/share/gnome-shell/extensions
cp -a work/sources/smart-workspace-manager \
  ~/.local/share/gnome-shell/extensions/smart-workspace-manager@local
```

The extension is optional. If using a different window-moving workspace
extension, disable it in this session or adapt it to skip migration while
`Meta.prefs_get_per_monitor_workspaces()` is true.

## Validation

After installation, run the nested two-monitor smoke check from a Wayland
session:

```sh
python3 packaging/validate-runtime.py
```

It launches a disposable Shell under a private D-Bus session. The automation
checks independent activation on two simulated monitors, dynamic workspace
removal, and that all Mutter/Shell libraries came from the private runtime.
The log is written under `~/.cache/per-monitor-workspaces/`.

## Session safety

The custom session has a dedicated `org.gnome.Shell.PerMonitor.service`; it
keeps custom library paths inside that process. Do not override Ubuntu's
`org.gnome.Shell@wayland.service`, because the normal Ubuntu session also uses
it. The install and uninstall scripts manage only the dedicated session and
runtime.

See [NOTICE](NOTICE) for upstream licensing information.
