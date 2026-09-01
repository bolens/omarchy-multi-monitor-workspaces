import Quickshell
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Hyprland
import qs.Commons
import qs.Ui
import "Model.js" as Model

BarWidget {
  id: root
  moduleName: Model.PLUGIN_ID
  property bool settingsOpen: false
  property var registeredService: null
  property string registeredScreenName: ""
  property int registeredGeneration: 0
  readonly property var workspaceService: bar && bar.shell && typeof bar.shell.serviceFor === "function" ? bar.shell.serviceFor(moduleName) : null
  readonly property var effectiveSettings: workspaceService ? workspaceService.effectiveSettings : Model.sanitizeSettings(settings)
  readonly property var barScreen: root.QsWindow.window ? root.QsWindow.window.screen : null
  readonly property string screenName: barScreen ? barScreen.name : ""
  readonly property var monitor: barScreen ? Hyprland.monitorFor(barScreen) : null
  readonly property int activeWorkspaceId: monitor && monitor.activeWorkspace ? monitor.activeWorkspace.id : 0
  // Registration is the single monitor-set snapshot for every presentation.
  // This prevents independently observed compositor hotplug frames from
  // temporarily assigning overlapping banks to different bar instances.
  readonly property var bankWorkspaceIds: {
    if (workspaceService && screenName) {
      workspaceService.topologySerial
      return workspaceService.workspaceIdsFor(screenName)
    }
    return Model.workspaceIds(Model.bankIndex(effectiveSettings,screenName,screenName ? [screenName] : []),effectiveSettings.count)
  }
  readonly property int monitorBankIndex: bankWorkspaceIds.length
    ? Math.floor((bankWorkspaceIds[0]-1)/effectiveSettings.count) : 0
  readonly property real trailingGap: root.vertical ? 0 : Style.spaceReal(1.5)

  function workspaceById(id) {
    var values = Hyprland.workspaces.values
    for (var index = 0; index < values.length; index++) if (values[index].id === id) return values[index]
    return null
  }
  function occupied(id) { var workspace = workspaceById(id); return workspace !== null && workspace.toplevels.values.length > 0 }
  function colorFor(role) {
    if (role === "accent") return Color.bar.active
    if (role === "urgent") return bar ? bar.urgent : Color.urgent
    if (role === "muted") return Color.muted
    return bar ? bar.barForeground : Color.foreground
  }
  function actionFor(id, action) {
    if (!bar || id <= 0) return false
    var command = action === "move" ? "hl.dsp.move({ workspace = \"" + id + "\" })"
      : (action === "move-silent" ? "hl.dsp.move({ workspace = \"" + id + "\", silent = true })"
      : "hl.dsp.focus({ workspace = \"" + id + "\" })")
    bar.run("hyprctl dispatch " + Util.shellQuote(command))
    return true
  }
  function focusRelative(delta) {
    var target = Model.scrollTarget(activeWorkspaceId, delta, bankWorkspaceIds, effectiveSettings.wrapScroll)
    return actionFor(target, "focus")
  }
  function showSettings(page) { settingsContent.page = page || "general"; settingsOpen = true; Qt.callLater(function(){settingsContent.applyScroll("top")}) }
  function closeSettings() { settingsOpen = false }
  function close() { closeSettings() }
  function workspaceDiagnostics() {
    return bankWorkspaceIds.map(function(id) {
      var workspace=workspaceById(id), active=root.activeWorkspaceId===id || (workspace!==null && workspace.active===true)
      return {id:id,monitorActive:root.activeWorkspaceId===id,workspaceActive:workspace!==null ? workspace.active : null,
        active:active,label:Model.labelFor(id,Model.localNumber(id,root.monitorBankIndex,root.effectiveSettings.count),root.effectiveSettings.labelMode,active,root.occupied(id),root.effectiveSettings)}
    })
  }
  function settingsStatus() { return {open:settingsOpen && settingsPanel.visible, requestedOpen:settingsOpen,
    page:settingsContent.page, screen:screenName, bank:monitorBankIndex,
    labelMode:effectiveSettings.labelMode, activeWorkspaceId:activeWorkspaceId, workspaces:workspaceDiagnostics(),
    panelWidth:settingsPanel.contentWidth, panelHeight:settingsPanel.contentHeight,
    contentHeight:settingsContent.contentHeight, scrollY:settingsContent.contentY,
    scrollMaximum:settingsContent.maximumContentY} }
  function scrollSettings(position) { if (!settingsOpen) return "error: settings are closed"; return settingsContent.applyScroll(position) }
  function syncRegistration() {
    var nextName = screenName
    if (registeredService === workspaceService && registeredScreenName === nextName) return
    if (registeredService) registeredService.unregisterWidget(registeredScreenName, root, registeredGeneration)
    registeredService = null; registeredScreenName = ""; registeredGeneration = 0
    if (workspaceService && nextName) {
      registeredService = workspaceService; registeredScreenName = nextName
      registeredGeneration = Number(workspaceService.registerWidget(nextName, root) || 0)
      workspaceService.configure(settings, true)
    }
  }

  implicitWidth: grid.implicitWidth + trailingGap
  implicitHeight: grid.implicitHeight
  GridLayout {
    id: grid
    anchors.fill: parent
    anchors.rightMargin: root.trailingGap
    columns: root.vertical ? 1 : root.bankWorkspaceIds.length
    columnSpacing: root.vertical ? 0 : Style.space(1)
    rowSpacing: root.vertical ? Style.space(2) : 0
    Repeater {
      model: root.bankWorkspaceIds
      WidgetButton {
        required property int modelData
        readonly property var workspace: root.workspaceById(modelData)
        readonly property bool workspaceOccupied: workspace !== null && workspace.toplevels.values.length > 0
        readonly property bool workspaceActive: root.activeWorkspaceId === modelData || (workspace !== null && workspace.active === true)
        readonly property int localNumber: Model.localNumber(modelData, root.monitorBankIndex, root.effectiveSettings.count)
        bar: root.bar
        visible: root.effectiveSettings.showEmpty || workspaceOccupied || workspaceActive
        text: Model.labelFor(modelData, localNumber, root.effectiveSettings.labelMode, workspaceActive, workspaceOccupied, root.effectiveSettings)
        active: workspaceActive
        foreground: root.colorFor(Model.colorRoleFor(root.effectiveSettings.labelMode, workspaceActive, workspaceOccupied, root.effectiveSettings))
        activeColor: root.colorFor(root.effectiveSettings.activeColorRole)
        opacity: Model.opacityFor(root.effectiveSettings.labelMode, workspaceActive, workspaceOccupied, root.effectiveSettings)
        horizontalMargin: root.effectiveSettings.horizontalMargin
        verticalPadding: root.effectiveSettings.verticalPadding
        fixedWidth: root.vertical ? root.barSize : Style.space(root.effectiveSettings.buttonWidth)
        fixedHeight: root.barSize
        tooltipText: root.effectiveSettings.showTooltips ? "Workspace " + modelData + " · bank " + (root.monitorBankIndex + 1) + " · " + root.screenName : ""
        onPressed: function(button) {
          if (button === Qt.RightButton) root.workspaceService ? root.workspaceService.openSettingsFor(root, "general") : root.showSettings("general")
          else if (button === Qt.MiddleButton) root.actionFor(modelData, "move-silent")
          else root.actionFor(modelData, root.effectiveSettings.clickAction)
        }
        onWheelMoved: function(delta) { root.focusRelative(delta > 0 ? -1 : 1) }
      }
    }
  }
  KeyboardPanel {
    id: settingsPanel
    anchorItem: grid
    owner: root
    bar: root.bar
    open: root.settingsOpen
    focusTarget: settingsContent.initialFocusTarget
    contentWidth: fittedContentWidth(Style.space(430))
    contentHeight: fittedContentHeight(settingsContent.implicitHeight, Style.space(620))
    onOpenChanged: if (!open) root.settingsOpen = false
    SettingsPanel { id: settingsContent; anchors.fill: parent; controller: root }
  }
  Component.onCompleted: { Hyprland.refreshMonitors(); Hyprland.refreshWorkspaces(); syncRegistration() }
  Component.onDestruction: if (registeredService) registeredService.unregisterWidget(registeredScreenName, root, registeredGeneration)
  onWorkspaceServiceChanged: syncRegistration()
  onScreenNameChanged: syncRegistration()
  onSettingsChanged: if (workspaceService) workspaceService.configure(settings, true)
}
