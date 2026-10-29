# Ubuntu 24.04 per-monitor session

The GDM entry launches `gnome-session --session=ubuntu-per-monitor-workspaces`.
Its dedicated session target starts `org.gnome.Shell.PerMonitor.service`.
Custom library and typelib paths belong only to that service; the launcher
must not export them or import them into the systemd user manager. Do not
override `org.gnome.Shell@wayland.service`, which normal Ubuntu also uses.

After building/installing into `~/.local/share/per-monitor-workspaces/usr`, run
`prepare-runtime.sh` (requires patchelf; `PATCHELF` can specify its executable).
This copies Ubuntu's Yaru resources and makes Shell's RUNPATH relative to its
executable. Shell's introspection initialization understands these `$ORIGIN`
entries and searches the matching installed libraries and typelibs first.
Without that step, moving the runtime from home to `/opt` loads duplicate
Clutter libraries through compiled absolute introspection paths.

Run `sudo ./install-login-session.sh` to copy the prepared runtime to `/opt`,
install the root-owned GDM entry/launcher, and install the dedicated units and
session files in the selected user's configuration. It reloads that user's
systemd manager without restarting the currently running Shell.

Run `python3 ./validate-runtime.py` from an existing desktop session to start
a disposable nested Shell on a private D-Bus session with two simulated
monitors. It verifies loaded library paths, independent workspace activation,
and workspace removal/renumbering, then exits. It does not verify physical
DisplayLink output handling or touchpad gestures.

Choose the normal Ubuntu entry to use the distribution compositor. The custom
units are requested only by the custom session target. The installer leaves
existing Ubuntu Shell service overrides alone; remove an old override from an
earlier version of this project before installing if one is still enabled.
