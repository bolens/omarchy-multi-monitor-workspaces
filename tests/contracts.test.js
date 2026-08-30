const assert = require("node:assert/strict")
const fs = require("node:fs")
const path = require("node:path")
const root = path.join(__dirname, "..")
const read = file => fs.readFileSync(path.join(root, file), "utf8")
const service = read("Service.qml"), widget = read("BarWidget.qml"), settings = read("SettingsPanel.qml"), model = read("Model.js")
const capture = read("scripts/capture-screenshots"), live = read("scripts/verify-live")
const qmlRuntimeRunner = read("tests/run_qml_runtime.sh")
for (const [name, source] of [["Service",service],["BarWidget",widget]])
  assert.doesNotMatch(source, /\bProcess\s*\{|execDetached|quickshell\s+--|\bqs\s+/, `${name} must not launch subprocesses or shells`)
assert.match(service, /target:\s*"multi-monitor-workspaces"/)
for (const method of ["status","registeredMonitors","workspaceIds","activate","openSettings","openAppearance","openMonitorSettings","openMonitorAppearance","closeSettings","settingsStatusFor","scrollSettingsFor","setSettings","resetSettings"])
  assert.match(service, new RegExp(`function ${method}\\(`), `missing IPC ${method}`)
assert.match(service, /interval:\s*75/, "settings writes must be coalesced")
assert.equal((service.match(/\bTimer\s*\{/g)||[]).length,1,"service must not add polling timers beyond the coalesced commit")
assert.match(service, /source\.length>65536/, "IPC settings JSON must have a deterministic size bound")
assert.match(service, /settings payload has no supported keys/, "IPC must reject unknown-only settings payloads")
assert.match(service, /Model\.mergePatchObjects\(pendingPatch \|\| \(\{\}\),requested\)/, "coalesced patches must merge with queued field intent")
assert.match(service, /registrationGeneration|registrationSerial/)
assert.match(service, /property int topologySerial: 0/, "service must expose topology separately from widget generations")
assert.match(service, /topologySerial\+\+/, "attach and detach must invalidate topology-dependent presentations")
assert.match(service, /expected > 0 && record\.generation !== expected/, "stale teardown must not remove a newer registration")
assert.match(service, /pendingPatch=Model\.mergePatchObjects\(changes,pendingPatch \|\| \(\{\}\)\)/, "failed field intents must remain retryable")
assert.match(service, /plugin entry removed before settings commit/, "queued writes must not resurrect a concurrently removed plugin")
assert.match(service, /isRegisteredInstance\(preferred\)/, "detached monitor widgets must not win settings routing")
assert.match(service, /record\.instance\.closeSettings/, "same-screen replacement must close the displaced panel before publishing its successor")
assert.match(service, /property string persistenceError:/, "persistence failures must have independent lifetime")
assert.match(service, /property string requestError:/, "request failures must not share persistence state")
assert.match(service, /healthy:persistenceError===""&&requestError===""/, "health must retain unresolved persistence failures")
assert.match(service, /revision < appliedRevision/, "stale presentation settings must not overwrite a committed revision")
assert.match(service, /shellConfigSnapshot:[^\n]*shell\.shellConfig[\s\S]*function shellEntry\(\)/, "revision authority must survive service reconstruction in shell config")
assert.match(widget, /workspaceService\.configure\(settings, true\)/, "bar-entry settings must seed the keep-loaded service")
assert.doesNotMatch(widget, /IpcHandler/, "per-monitor presentations must not race for the IPC endpoint")
assert.match(widget, /workspaceService\.workspaceIdsFor\(screenName\)/,
  "all presentations must use the service's single monitor-set snapshot during hotplug")
assert.match(widget, /workspaceService\.topologySerial/,
  "presentations must react to both monitor attachment and removal")
assert.doesNotMatch(widget, /Hyprland\.monitors\.values/,
  "presentations must not independently race compositor monitor snapshots")
assert.match(widget, /function close\(\)\s*\{\s*closeSettings\(\)\s*\}/, "KeyboardPanel owner contract is required")
assert.match(widget, /onWheelMoved/, "workspace wheel navigation must use the stock click target")
assert.match(widget, /activeWorkspaceId === modelData \|\| \(workspace !== null && workspace\.active === true\)/,
  "active detection must retain Quickshell workspace state when monitor activeWorkspace is unavailable")
assert.match(widget, /Component\.onDestruction:[\s\S]*unregisterWidget/, "destroyed monitor instances must unregister")
assert.match(model, /uniqueNames\(value,100\)\.sort\(\)/, "live fallback monitor order must be deterministic through every supported bank")
assert.match(model, /Object\.keys\(value\)\.sort\(\)/, "monitor override serialization must be deterministic")
assert.match(settings, /Flickable[\s\S]*ScrollBar\.vertical/, "the complete settings surface must remain reachable")
assert.match(settings, /wrapMode:Text\.WordWrap/g, "helper text must wrap inside visual bounds")
assert.match(settings, /implicitHeight:\s*Style\.space\(560\)/, "settings geometry must be deterministic")
assert.match(settings, /workspaceIdsFor\(modelData\)\[0\]/, "monitor editors must display the effective bank after priority and collision resolution")
assert.match(settings, /function setWorkspaceGlyph\(workspaceId, value\)/, "settings must update one global workspace glyph without replacing its peers")
assert.match(settings, /model:root\.controller\.bankWorkspaceIds/, "glyph editors must target the panel monitor's global workspace bank")
assert.match(qmlRuntimeRunner, /leaked_runtime_processes\(\)/,
  "the isolated runtime runner must detect only its own leaked Quickshell harnesses")
assert.match(qmlRuntimeRunner, /Leaked Quickshell runtime harnesses:/,
  "the isolated runtime runner must fail with explicit leak evidence")
for (const [name, source] of [["capture",capture],["live verifier",live]]) {
  assert.match(source,/probe=.*multi-monitor-workspaces status/,
    `${name} must inspect the candidate response instead of trusting qs exit status`)
  assert.match(source,/\.ipcVersion == 1/,
    `${name} must reject unrelated Quickshell IPC processes`)
}
assert.match(capture,/local status=\$\?/,
  "capture cleanup must preserve the failing command status")
assert.match(capture,/hl\.dsp\.focus\(\{ workspace/,
  "capture must use an empty workspace instead of retaining private window content")
assert.match(capture,/hl\.dsp\.focus\(\{ monitor/,
  "capture must restore the selected and previously focused monitor")
assert.match(capture,/grim -o "\$monitor"/,
  "settings evidence must include the complete monitor-height panel")
console.log("Multi-monitor workspace QML and IPC contracts passed")
