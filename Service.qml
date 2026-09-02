pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Io
import "Model.js" as Model

Item {
  id: root
  property var shell: null
  property var settings: ({})
  property var effectiveSettings: Model.sanitizeSettings(settings)
  property var widgetInstances: []
  property int registrationSerial: 0
  property int topologySerial: 0
  property int mutationSerial: 0
  property string persistenceError: ""
  property string requestError: ""
  readonly property string lastError: persistenceError !== "" ? persistenceError : requestError
  property var pendingPatch: null
  property int appliedRevision: -1
  readonly property int settingsVersion: Model.SETTINGS_VERSION
  readonly property int ipcVersion: 1
  readonly property var shellConfigSnapshot: shell && shell.shellConfig ? shell.shellConfig : null
  function shellEntry() {
    var config=shellConfigSnapshot, layout=config && config.bar ? config.bar.layout : null
    if (!layout) return null
    var sections=["left","center","right"]
    for (var sectionIndex=0;sectionIndex<sections.length;sectionIndex++) {
      var entries=layout[sections[sectionIndex]]
      if (!Array.isArray(entries)) continue
      for (var entryIndex=0;entryIndex<entries.length;entryIndex++)
        if (Model.entryId(entries[entryIndex])===Model.PLUGIN_ID) return entries[entryIndex]
    }
    return null
  }
  function configure(value, authoritative) {
    var source=Model.isObject(value) ? value : ({}), revision=Model.boundedInteger(source._multiMonitorWorkspacesRevision,0,0,2147483647)
    var stored=shellEntry(), storedRevision=stored ? Model.boundedInteger(stored._multiMonitorWorkspacesRevision,0,0,2147483647) : -1
    if (stored && storedRevision>=revision) { source=stored; revision=storedRevision; authoritative=true }
    if (revision < appliedRevision || (revision === appliedRevision && !authoritative && appliedRevision >= 0)) return false
    var current=Model.sanitizeSettings(source)
    effectiveSettings=pendingPatch ? Model.mergeSettings(current,pendingPatch) : current
    appliedRevision=revision; return true
  }
  function syncFromShell() { var stored=shellEntry(); return stored ? configure(stored,true) : false }
  function fail(message, persistent) {
    var value=String(message || "unknown workspace error")
    if (persistent===true) persistenceError=value
    else requestError=value
    console.warn("Multi-Monitor Workspaces: " + value); return "error: " + value
  }
  function clearRequestError() { requestError="" }
  function registerWidget(screenName, instance) {
    if (!instance) return 0
    var key = String(screenName || "").trim(); if (!key) return 0
    var existed=widgetFor(key)!==null
    widgetInstances.forEach(function(record) {
      if (record.screen===key && record.instance!==instance && record.instance.closeSettings) record.instance.closeSettings()
    })
    registrationSerial++; var generation = registrationSerial
    widgetInstances = widgetInstances.filter(function(record) { return record.instance !== instance && record.screen !== key })
      .concat([{screen:key, instance:instance, generation:generation}]).sort(function(a,b) { return a.screen.localeCompare(b.screen) })
    if (!existed) topologySerial++
    return generation
  }
  function unregisterWidget(screenName, instance, generation) {
    var key = String(screenName || "").trim(), expected = Number(generation || 0)
    var previousLength=widgetInstances.length
    widgetInstances = widgetInstances.filter(function(record) { return record.instance !== instance || record.screen !== key || (expected > 0 && record.generation !== expected) })
    if (widgetInstances.length!==previousLength) topologySerial++
  }
  function widgetFor(screenName) { var key=String(screenName || "").trim(); for (var index=0; index<widgetInstances.length; index++) if (widgetInstances[index].screen===key) return widgetInstances[index].instance; return null }
  function isRegisteredInstance(instance) { for (var index=0;index<widgetInstances.length;index++) if (widgetInstances[index].instance===instance) return true; return false }
  function monitorNames() { return widgetInstances.map(function(record) { return record.screen }).sort() }
  function openSettingsFor(preferred, page) {
    if (preferred && !isRegisteredInstance(preferred)) return fail("settings widget is no longer registered")
    var selected = preferred || (widgetInstances.length ? widgetInstances[0].instance : null)
    if (!selected || typeof selected.showSettings !== "function") return fail("no live bar widget is available")
    widgetInstances.forEach(function(record) { if (record.instance !== selected && record.instance.closeSettings) record.instance.closeSettings() })
    selected.showSettings(page || "general"); clearRequestError(); return "opened"
  }
  function openSettingsOn(screen, page) { var widget=widgetFor(screen); return widget ? openSettingsFor(widget,page) : fail("no live bar widget for monitor: " + screen) }
  function closeSettings() { var closed=false; widgetInstances.forEach(function(record) { if (record.instance.closeSettings) { record.instance.closeSettings(); closed=true } }); if (closed) { clearRequestError(); return "closed" } return fail("no live bar widget is available") }
  function settingsStatusFor(screen) { var widget=widgetFor(screen); if (!widget) return fail("no live bar widget for monitor: " + screen); clearRequestError(); return JSON.stringify(widget.settingsStatus()) }
  function scrollSettingsFor(screen,position) { var widget=widgetFor(screen); return widget ? widget.scrollSettings(position) : fail("no live bar widget for monitor: " + screen) }
  function updateSettings(patch) {
    if (!Model.isObject(patch)) return fail("settings payload must be an object")
    var requested=Model.settingsPatch(patch)
    if (Object.keys(requested).length===0 && Object.keys(patch).length>0) return fail("settings payload has no supported keys")
    var changes=Model.mergePatchObjects(pendingPatch || ({}),requested)
    var clean=Model.mergeSettings(effectiveSettings,changes)
    if (JSON.stringify(clean)===JSON.stringify(effectiveSettings) && !pendingPatch) { clearRequestError(); return "unchanged" }
    pendingPatch=changes; effectiveSettings=clean; clearRequestError(); commitTimer.restart(); return "queued"
  }
  function parseSettingsPayload(payload) {
    var source=String(payload || "")
    if (source.length>65536) return fail("settings JSON exceeds 65536 bytes")
    try { return updateSettings(JSON.parse(source)) }
    catch(error) { return fail("invalid settings JSON") }
  }
  function flushSettings() {
    if (!pendingPatch) return false
    var changes=pendingPatch; pendingPatch=null
    try {
      if (!shell || typeof shell.updateEntryInline !== "function") throw new Error("shell settings API unavailable")
      var stored=shellEntry()
      if (shellConfigSnapshot!==null && !stored) throw new Error("plugin entry removed before settings commit")
      var storedRevision=stored ? Model.boundedInteger(stored._multiMonitorWorkspacesRevision,0,0,2147483647) : -1
      var candidate=Model.mergeSettings(stored || effectiveSettings,changes)
      var revision=Math.max(appliedRevision+1,storedRevision+1,mutationSerial+1), entry={id:Model.PLUGIN_ID,_multiMonitorWorkspacesSettingsVersion:Model.SETTINGS_VERSION,_multiMonitorWorkspacesRevision:revision}
      Object.keys(candidate).forEach(function(key){entry[key]=candidate[key]})
      shell.updateEntryInline(Model.PLUGIN_ID,entry); effectiveSettings=candidate; appliedRevision=revision; mutationSerial++; persistenceError=""; return true
    } catch(error) { pendingPatch=Model.mergePatchObjects(changes,pendingPatch || ({})); effectiveSettings=Model.mergeSettings(effectiveSettings,pendingPatch); fail(String(error && error.message ? error.message : error),true); return false }
  }
  function resetSettings() { return updateSettings(Model.DEFAULTS) }
  function workspaceIdsFor(screen) { return Model.workspaceIds(Model.bankIndex(effectiveSettings,screen,monitorNames()),effectiveSettings.count) }
  function allocationObject() {
    var result={}, names=monitorNames()
    for (var index=0;index<names.length;index++) {
      var ids=workspaceIdsFor(names[index])
      result[names[index]]={bank:ids.length ? Math.floor((ids[0]-1)/effectiveSettings.count) : 0,workspaceIds:ids}
    }
    return result
  }
  function workspaceIdsResponse(screen) {
    var key=String(screen || "").trim()
    if (!widgetFor(key)) return fail("no live bar widget for monitor: " + key)
    clearRequestError(); return JSON.stringify(workspaceIdsFor(key))
  }
  function activate(screen,localNumber,action) {
    var widget=widgetFor(screen); if (!widget) return fail("no live bar widget for monitor: " + screen)
    var ids=workspaceIdsFor(screen), local=Number(localNumber), requested=String(action || "")
    if (!isFinite(local) || Math.round(local)!==local || local<1 || local>ids.length) return fail("workspace must be between 1 and " + ids.length)
    if (["focus","move","move-silent"].indexOf(requested)<0) return fail("invalid workspace action: " + requested)
    if (!widget.actionFor(ids[local-1],requested)) return fail("workspace action failed")
    clearRequestError(); return "activated"
  }
  function statusObject() { return {healthy:persistenceError===""&&requestError==="",lastError:lastError,persistenceError:persistenceError,requestError:requestError,ipcVersion:ipcVersion,settingsVersion:settingsVersion,
    mutationSerial:mutationSerial,registrationSerial:registrationSerial,topologySerial:topologySerial,appliedRevision:appliedRevision,
    shellConfigAvailable:shellConfigSnapshot!==null,shellEntryFound:shellEntry()!==null,
    shellEntryRevision:shellEntry() ? Model.boundedInteger(shellEntry()._multiMonitorWorkspacesRevision,0,0,2147483647) : -1,
    monitors:monitorNames(),allocations:allocationObject(),settings:effectiveSettings,pending:pendingPatch!==null} }
  IpcHandler {
    target: "multi-monitor-workspaces"
    function status(): string { return JSON.stringify(root.statusObject()) }
    function registeredMonitors(): string { return JSON.stringify(root.monitorNames()) }
    function workspaceIds(screen: string): string { return root.workspaceIdsResponse(screen) }
    function activate(screen: string, workspace: int, action: string): string { return root.activate(screen,workspace,action) }
    function openSettings(): string { return root.openSettingsFor(null,"general") }
    function openAppearance(): string { return root.openSettingsFor(null,"appearance") }
    function openMonitorSettings(screen: string): string { return root.openSettingsOn(screen,"general") }
    function openMonitorAppearance(screen: string): string { return root.openSettingsOn(screen,"appearance") }
    function closeSettings(): string { return root.closeSettings() }
    function settingsStatusFor(screen: string): string { return root.settingsStatusFor(screen) }
    function scrollSettingsFor(screen: string, position: string): string { return root.scrollSettingsFor(screen,position) }
    function setSettings(payload: string): string { return root.parseSettingsPayload(payload) }
    function resetSettings(): string { return root.resetSettings() }
  }
  Timer { id: commitTimer; interval: 75; repeat: false; onTriggered: root.flushSettings() }
  onSettingsChanged: configure(settings, false)
  onShellConfigSnapshotChanged: { if (syncFromShell() && pendingPatch) commitTimer.restart() }
  Component.onCompleted: { configure(settings, false); syncFromShell() }
}
