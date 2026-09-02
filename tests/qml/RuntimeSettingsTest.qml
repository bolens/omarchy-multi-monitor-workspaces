pragma ComponentBehavior: Bound
import Quickshell
import QtQuick
import "Model.js" as Model

ShellRoot {
  QtObject {
    id: serviceMock
    property var effectiveSettings: Model.sanitizeSettings({labelMode:"hybrid",workspaceGlyphs:{"1":"🎮"}})
    property var lastPatch: ({})
    property string lastError: ""
    property int registrationSerial: 2
    property int topologySerial: 2
    function updateSettings(patch) { lastPatch=patch; effectiveSettings=Model.mergeSettings(effectiveSettings,patch); return "queued" }
    function resetSettings() {}
    function monitorNames() { return ["DP-1","DP-3"] }
    function workspaceIdsFor(screen) { return screen==="DP-1" ? [1,2,3,4,5,6,7,8,9,10] : [11,12,13,14,15,16,17,18,19,20] }
  }
  QtObject {
    id: controllerMock
    property var workspaceService: serviceMock
    property var effectiveSettings: serviceMock.effectiveSettings
    property string screenName: "DP-1"
    property int monitorBankIndex: 0
    property var bankWorkspaceIds: [1,2,3,4,5,6,7,8,9,10]
    function closeSettings() {}
  }
  SettingsPanel { id: panel; width:430; height:592; controller:controllerMock; page:"appearance" }
  function descendant(item,name) {
    if (!item) return null
    if (item.objectName===name) return item
    var children=item.children || []
    for (var index=0;index<children.length;index++) { var found=descendant(children[index],name); if (found) return found }
    return null
  }
  function countPrefix(item,prefix) {
    if (!item) return 0
    var total=String(item.objectName || "").indexOf(prefix)===0 ? 1 : 0, children=item.children || []
    for (var index=0;index<children.length;index++) total+=countPrefix(children[index],prefix)
    return total
  }
  Component.onCompleted: Qt.callLater(function() {
    if (Object.keys(serviceMock.lastPatch).length!==0) throw new Error("settings controls mutated state during initialization")
    var first=descendant(panel,"workspaceGlyphEditor-1"), tenth=descendant(panel,"workspaceGlyphEditor-10")
    if (!first || !tenth || first.text!=="🎮" || tenth.text!=="" || countPrefix(panel,"workspaceGlyphEditor-")!==10)
      throw new Error("per-bank glyph editors did not render deterministically")
    if (first.width<=0 || first.width>panel.width || first.x+first.width>panel.width) throw new Error("workspace glyph editor escaped panel bounds")
    tenth.text="󰄛"; tenth.editingFinished()
    if (serviceMock.lastPatch.workspaceGlyphs["1"]!=="🎮" || serviceMock.lastPatch.workspaceGlyphs["10"]!=="󰄛")
      throw new Error("workspace glyph edit replaced a peer mapping")
    first.text=""; first.editingFinished()
    if (serviceMock.lastPatch.workspaceGlyphs["1"]!==undefined || serviceMock.lastPatch.workspaceGlyphs["10"]!=="󰄛")
      throw new Error("clearing a workspace glyph removed the wrong mapping")
    panel.applyScroll("bottom")
    if (panel.contentHeight<=0 || panel.maximumContentY<=0 || panel.contentY!==panel.maximumContentY) throw new Error("full appearance editor is not scrollable")
    console.log("MMW_QML_SETTINGS_OK"); Qt.quit()
  })
}
