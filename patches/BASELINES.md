# Patch baselines

The patches in `patches/` were built and validated against these exact upstream
revisions. The GNOME 46 series targets Ubuntu 24.04's Mutter 46.2 and Shell
46.0 API. Newer GNOME branches can change workspace and monitor APIs and need a
separate port.

| Component | Upstream | Base commit | Version |
| --- | --- | --- | --- |
| Mutter | `https://github.com/GNOME/mutter.git` | `02050414855b370dbf2b08a971c8b332f7b3c9f4` | 46.2 |
| GNOME Shell | `https://github.com/GNOME/gnome-shell.git` | `0463511457612ca87f7426b3b01356d1d85bee9b` | 46.0 |
| Smart Workspace Manager | `https://github.com/devops-dude-dinodam/smart-workspace-manager.git` | `a4fa366445608f6d865461d289507dbd08e2fd65` | 2 (GNOME 46) |

Mutter and Shell are GNOME projects licensed under GPL-2.0-or-later. The
extension patch modifies a project whose upstream license is MIT. Keep those
upstream notices when distributing complete source trees.
