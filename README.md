# Monitor Workspace Dots for Omarchy

A compact Omarchy Quattro bar widget that displays workspaces independently on
each monitor. The focused workspace is bright, occupied workspaces are muted,
and empty persistent workspaces are dim.

By default the widget shows up to five dots on each monitor. Clicking a dot
activates that monitor's corresponding Hyprland workspace.

## Install

```sh
omarchy plugin add https://github.com/derluke/omarchy-monitor-workspaces.git --enable
omarchy plugin disable omarchy.workspaces
omarchy bar move io.github.derluke.monitor-workspaces --section left --after omarchy.menu
```

The plugin does not edit Hyprland or other user configuration.

## Independent workspace banks

For five persistent workspaces per monitor, use the Lua version of
[split-monitor-workspaces](https://github.com/zjeffer/split-monitor-workspaces).
It requires Hyprland 0.55 or newer. Follow its release-branch guidance so the
package version matches your installed Hyprland version.

An opt-in Omarchy example is included at
[`examples/independent-workspaces.lua`](examples/independent-workspaces.lua).
Review it, replace the monitor names, and append it to
`~/.config/hypr/bindings.lua`. It configures:

- `Super+1..5`: first monitor workspace 1..5
- `Super+Ctrl+1..5`: second monitor workspace 1..5
- Add `Shift`: move the active window and follow it
- Add `Shift+Alt`: move the active window silently
- `Super+Tab` / `Super+Shift+Tab`: cycle within the focused monitor
- `Super+Ctrl+Shift+Left/Right`: move a window to a connected adjacent monitor

The directional move is guarded: it does nothing when no monitor exists in
that direction.

## Configure

The default maximum is five dots. Change it inline in
`~/.config/omarchy/shell.json` if desired:

```json
{
  "id": "io.github.derluke.monitor-workspaces",
  "count": 5
}
```

Persistent workspace rules are recommended so empty dots remain visible.

## Remove

```sh
omarchy plugin remove io.github.derluke.monitor-workspaces
omarchy plugin enable omarchy.workspaces --section left
```

Removing the widget does not remove any separately installed Hyprland package
or changes copied manually from the example.

## Permissions and dependencies

The widget runs inside `omarchy-shell`, reads Quickshell's Hyprland workspace
model, and dispatches workspace activation when clicked. It executes no shell
commands, makes no network requests, and requires no elevated privileges.

Runtime requirements:

- Omarchy 4 (Quattro)
- The built-in Omarchy bar
- Quickshell's Hyprland integration

The external `split-monitor-workspaces` Lua package is optional and is only
needed for independent persistent workspace numbering.

## License

MIT. This widget was derived from Omarchy's built-in workspace widget.
