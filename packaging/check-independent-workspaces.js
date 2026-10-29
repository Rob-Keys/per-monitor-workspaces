// Run only inside a disposable nested Shell with two dummy monitors, using
// --automation-script. It does not change desktop preferences.
import GLib from 'gi://GLib';

function check(condition, message) {
    if (!condition)
        throw new Error(message);
}

export async function run() {
    const [, bytes] = GLib.file_get_contents('/proc/self/maps');
    const libraries = [...new Set(new TextDecoder().decode(bytes).split('\n')
        .filter(line => /libmutter.*\.so|libst-14\.so|libshell-14\.so/.test(line))
        .map(line => line.trim().split(/\s+/).at(-1)))];
    check(libraries.every(path => path.startsWith('/opt/per-monitor-workspaces/')),
        `Mixed runtime libraries: ${libraries.join(', ')}`);
    check(global.display.get_n_monitors() === 2, 'Expected two nested monitors');

    const manager = global.workspace_manager;
    const now = global.get_current_time();
    while (manager.n_workspaces < 3)
        manager.append_new_workspace(false, now);
    const workspaces = [0, 1, 2].map(i => manager.get_workspace_by_index(i));
    const active = () => [0, 1].map(i =>
        manager.get_active_workspace_for_monitor_index(i).index());
    manager.activate_workspace_for_monitor_index(workspaces[0], 0, now);
    manager.activate_workspace_for_monitor_index(workspaces[0], 1, now);
    manager.activate_workspace_for_monitor_index(workspaces[1], 0, now);
    check(JSON.stringify(active()) === '[1,0]', `First monitor switch: ${active()}`);
    manager.activate_workspace_for_monitor_index(workspaces[2], 1, now);
    check(JSON.stringify(active()) === '[1,2]', `Second monitor switch: ${active()}`);
    manager.activate_workspace_for_monitor_index(workspaces[0], 0, now);
    check(JSON.stringify(active()) === '[0,2]', `Return switch: ${active()}`);
    manager.remove_workspace(workspaces[1], now);
    check(JSON.stringify(active()) === '[0,1]', `Workspace renumbering: ${active()}`);
    manager.remove_workspace(workspaces[2], now);
    check(active().every(i => i >= 0 && i < manager.n_workspaces),
        `Invalid workspace after removal: ${active()}`);
    print(`PER_MONITOR_CHECK_PASS ${JSON.stringify({active: active(), libraries})}`);
}
