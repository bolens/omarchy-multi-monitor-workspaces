import Quickshell
import QtQuick

ShellRoot {
  id: root
  property list<string> loadedMonitorPriority: ["DP-3", "DP-1"]
  QtObject {
    id: shellMock
    property int writes: 0
    property bool failWrites: false
    property var lastEntry: ({})
    property var shellConfig: ({bar:{layout:{left:[{id:"io.github.bolens.multi-monitor-workspaces",count:5,monitorPriority:root.loadedMonitorPriority,_multiMonitorWorkspacesRevision:4}]}}})
    function updateEntryInline(id, entry) { if (failWrites) throw new Error("simulated write failure"); if (id !== "io.github.bolens.multi-monitor-workspaces") throw new Error("wrong id"); writes++; lastEntry=entry; shellConfig=({bar:{layout:{left:[entry]}}}) }
  }
  QtObject { id: dp1; property bool opened:false; function showSettings(_page){opened=true} function closeSettings(){opened=false}
    function settingsStatus(){return {open:opened}} function scrollSettings(position){return position} function actionFor(_id,_action){return true} }
  QtObject { id: dp1Replacement; property bool opened:false; function showSettings(_page){opened=true} function closeSettings(){opened=false}
    function settingsStatus(){return {open:opened}} function scrollSettings(position){return position} function actionFor(_id,_action){return true} }
  QtObject { id: dp3; property bool opened:false; function showSettings(_page){opened=true} function closeSettings(){opened=false}
    function settingsStatus(){return {open:opened}} function scrollSettings(position){return position} function actionFor(_id,_action){return true} }
  Component { id: widgetFactory; QtObject { function showSettings(_page){} function closeSettings(){}
    function settingsStatus(){return {open:false}} function scrollSettings(position){return position} function actionFor(_id,_action){return true} } }
  Service { id: service; shell:shellMock }
  Component.onCompleted: Qt.callLater(function() {
    service.configure({id:"io.github.bolens.multi-monitor-workspaces",count:5,monitorPriority:["DP-3","DP-1"],_multiMonitorWorkspacesRevision:4},true)
    service.configure({id:"io.github.bolens.multi-monitor-workspaces",count:2,_multiMonitorWorkspacesRevision:1},true)
    if (service.effectiveSettings.count !== 5 || service.appliedRevision !== 4) throw new Error("shell revision floor accepted stale reconstructed presentation")
    var first=service.registerWidget("DP-3",dp3), second=service.registerWidget("DP-1",dp1)
    if (first < 1 || second <= first || service.monitorNames().join(",") !== "DP-1,DP-3") throw new Error("deterministic registration failed")
    if (service.topologySerial!==2) throw new Error("monitor attachment did not advance topology serial")
    dp1.opened=true
    var replacement=service.registerWidget("DP-1",dp1Replacement); service.unregisterWidget("DP-1",dp1,second)
    if (replacement <= second || service.monitorNames().join(",") !== "DP-1,DP-3" || service.widgetFor("DP-1")!==dp1Replacement)
      throw new Error("stale teardown won")
    if (dp1.opened || service.topologySerial!==2) throw new Error("same-screen replacement retained a displaced panel or changed topology")
    for (var churn=0;churn<500;churn++) {
      var generation=service.registerWidget("DP-1",dp1Replacement)
      service.unregisterWidget("DP-1",dp1Replacement,generation-1)
      if (service.widgetFor("DP-1")!==dp1Replacement) throw new Error("registration churn lost the current generation")
    }
    service.unregisterWidget("DP-3",dp3,first)
    if (service.topologySerial!==3) throw new Error("monitor removal did not advance topology serial")
    if (service.workspaceIdsFor("DP-1")[0]!==6) throw new Error("temporary monitor removal renumbered an explicitly prioritized bank")
    first=service.registerWidget("DP-3",dp3)
    if (service.topologySerial!==4) throw new Error("monitor reattachment did not advance topology serial")
    if (service.workspaceIdsFor("DP-3").join(",") !== "1,2,3,4,5") throw new Error("priority bank failed")
    if (service.workspaceIdsFor("DP-1").join(",") !== "6,7,8,9,10") throw new Error("second bank failed")
    var hotplugWidgets=[]
    for (var hotplug=0;hotplug<32;hotplug++) {
      var dynamicWidget=widgetFactory.createObject(service), dynamicName="HOTPLUG-"+String(hotplug+1).padStart(2,"0")
      hotplugWidgets.push({name:dynamicName,instance:dynamicWidget,generation:service.registerWidget(dynamicName,dynamicWidget)})
    }
    var seenBanks={}
    for (var attached=0;attached<hotplugWidgets.length;attached++) {
      var attachedBank=service.workspaceIdsFor(hotplugWidgets[attached].name)[0]
      if (seenBanks[attachedBank]) throw new Error("32-monitor hotplug produced overlapping workspace banks")
      seenBanks[attachedBank]=true
    }
    for (var removed=hotplugWidgets.length-1;removed>=0;removed-=2)
      service.unregisterWidget(hotplugWidgets[removed].name,hotplugWidgets[removed].instance,hotplugWidgets[removed].generation)
    if (service.monitorNames().length!==18) throw new Error("staggered hot-unplug retained removed presentations")
    if (service.topologySerial!==52) throw new Error("bulk attach/detach topology serial was not exact")
    for (var destroy=0;destroy<hotplugWidgets.length;destroy++) hotplugWidgets[destroy].instance.destroy()
    if (service.openSettingsOn("DP-3","appearance") !== "opened" || !dp3.opened || dp1.opened) throw new Error("settings routing failed")
    if (service.openSettingsOn("DP-1","general")!=="opened" || !dp1Replacement.opened || dp3.opened
        || service.openSettingsOn("DP-3","appearance")!=="opened" || dp1Replacement.opened || !dp3.opened)
      throw new Error("rapid cross-monitor panel handoff left multiple owners open")
    var staleWidget=widgetFactory.createObject(service), staleGeneration=service.registerWidget("STALE",staleWidget)
    service.unregisterWidget("STALE",staleWidget,staleGeneration)
    if (service.openSettingsFor(staleWidget,"general").indexOf("error:")!==0)
      throw new Error("detached presentation won a settings-open race")
    staleWidget.destroy(); service.requestError=""
    if (service.updateSettings([]).indexOf("error:") !== 0) throw new Error("invalid settings accepted")
    service.updateSettings({count:8}); service.flushSettings()
    if (shellMock.writes !== 1 || shellMock.lastEntry.count !== 8 || shellMock.lastEntry._multiMonitorWorkspacesRevision !== 5) throw new Error("settings write failed")
    var priorityReload=JSON.parse(JSON.stringify(shellMock.lastEntry))
    service.configure(priorityReload,true)
    if (service.effectiveSettings.monitorPriority.join(",") !== "DP-3,DP-1") throw new Error("monitor priority reset after save and reload")
    service.configure({id:"io.github.bolens.multi-monitor-workspaces",count:3,_multiMonitorWorkspacesRevision:4},true)
    if (service.effectiveSettings.count !== 8) throw new Error("stale presentation overwrote a committed revision")
    service.updateSettings({labelMode:"glyph"}); service.updateSettings({buttonWidth:31}); service.flushSettings()
    if (shellMock.lastEntry.labelMode !== "glyph" || shellMock.lastEntry.buttonWidth !== 31)
      throw new Error("coalescing lost an earlier patch in the same write window")
    service.updateSettings({labelMode:"hybrid"})
    var external=JSON.parse(JSON.stringify(shellMock.lastEntry)); external.buttonWidth=37; external._multiMonitorWorkspacesRevision++
    shellMock.shellConfig=({bar:{layout:{left:[external]}}}); service.syncFromShell(); service.flushSettings()
    if (shellMock.lastEntry.labelMode !== "hybrid" || shellMock.lastEntry.buttonWidth !== 37
        || shellMock.lastEntry._multiMonitorWorkspacesRevision !== external._multiMonitorWorkspacesRevision+1)
      throw new Error("queued field intent overwrote a concurrent shell setting")
    if (service.updateSettings({unknown:true}).indexOf("error:") !== 0
        || service.parseSettingsPayload("{").indexOf("error:") !== 0
        || service.parseSettingsPayload("x".repeat(65537)).indexOf("error:") !== 0)
      throw new Error("adversarial settings payload was accepted")
    if (service.activate("DP-1",0,"focus").indexOf("error:") !== 0
        || service.activate("DP-1",99,"focus").indexOf("error:") !== 0
        || service.activate("DP-1",1,"invalid").indexOf("error:") !== 0)
      throw new Error("invalid IPC workspace arguments were silently coerced")
    if (service.workspaceIdsResponse("missing").indexOf("error:") !== 0
        || service.activate("DP-1",1,"focus") !== "activated" || service.lastError !== "")
      throw new Error("monitor lookup or stale IPC error recovery failed")
    if (service.activate("DP-1",2,"focus") !== "activated") throw new Error("IPC activation failed")
    shellMock.failWrites=true; service.updateSettings({count:9}); service.flushSettings()
    if (service.pendingPatch === null || service.pendingPatch.count !== 9 || shellMock.lastEntry.count !== 8
        || service.lastError.indexOf("simulated") < 0) throw new Error("failed write intent was not retained without persistence")
    if (service.workspaceIdsResponse("DP-1").indexOf("[")!==0 || service.persistenceError.indexOf("simulated")<0
        || service.lastError.indexOf("simulated")<0 || service.statusObject().healthy)
      throw new Error("successful IPC masked an unresolved persistence failure")
    shellMock.failWrites=false
    var recoveryExternal=JSON.parse(JSON.stringify(shellMock.lastEntry)); recoveryExternal.buttonWidth=41; recoveryExternal._multiMonitorWorkspacesRevision++
    shellMock.shellConfig=({bar:{layout:{left:[recoveryExternal]}}}); service.syncFromShell(); service.flushSettings()
    if (shellMock.lastEntry.count!==9 || shellMock.lastEntry.buttonWidth!==41 || service.pendingPatch!==null || service.lastError!=="")
      throw new Error("retry did not merge retained intent with the latest external config")
    var beforeRemoval=JSON.parse(JSON.stringify(shellMock.lastEntry)), writesBeforeRemoval=shellMock.writes
    service.updateSettings({emptyGlyph:"E"})
    shellMock.shellConfig=({bar:{layout:{left:[]}}})
    if (service.syncFromShell()!==false || service.flushSettings()!==false || shellMock.writes!==writesBeforeRemoval
        || service.pendingPatch===null || service.pendingPatch.emptyGlyph!=="E" || service.lastError.indexOf("removed")<0)
      throw new Error("queued settings resurrected a concurrently removed plugin entry")
    beforeRemoval.buttonWidth=43; beforeRemoval._multiMonitorWorkspacesRevision++
    shellMock.shellConfig=({bar:{layout:{left:[beforeRemoval]}}}); service.syncFromShell()
    if (!service.flushSettings() || shellMock.lastEntry.emptyGlyph!=="E" || shellMock.lastEntry.buttonWidth!==43
        || service.pendingPatch!==null || service.lastError!=="")
      throw new Error("pending intent did not recover against a reappeared plugin entry")
    for (var cycle=0;cycle<100;cycle++) {
      if (service.openSettingsOn(cycle%2===0?"DP-1":"DP-3","appearance")!=="opened") throw new Error("settings open cycle failed")
      service.closeSettings()
    }
    console.log("MMW_QML_SERVICE_OK"); Qt.quit()
  })
}
