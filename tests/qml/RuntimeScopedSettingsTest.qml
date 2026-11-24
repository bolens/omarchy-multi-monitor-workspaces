pragma ComponentBehavior: Bound
import Quickshell
import QtQuick
import "Model.js" as Model

ShellRoot {
  id: root
  QtObject {
    id: scopedHost
    property bool rejectWrites: false
    property var untouched: ({theme: "preserved"})
    property var barConfig: ({layout: {left: [{id: Model.PLUGIN_ID, count: 5, followOmarchy: false, _multiMonitorWorkspacesRevision: 4}]}})
    function updateEntryInline(id, entry) {
      if (rejectWrites) return false
      var next = JSON.parse(JSON.stringify(barConfig))
      next.layout.left = next.layout.left.map(function(item) { return item.id === id ? entry : item })
      barConfig = next
      return true
    }
  }
  Service { id: service; shell: scopedHost }
  Timer {
    id: savedCheck
    interval: 180
    onTriggered: {
      if (scopedHost.barConfig.layout.left[0].count !== 12 || service.effectiveSettings.count !== 12
          || scopedHost.untouched.theme !== "preserved") throw new Error("scoped settings were not saved safely")
      scopedHost.rejectWrites = true
      service.updateSettings({count: 13})
      rejectedCheck.start()
    }
  }
  Timer {
    id: rejectedCheck
    interval: 180
    onTriggered: {
      if (scopedHost.barConfig.layout.left[0].count !== 12 || !service.pendingPatch
          || service.pendingPatch.count !== 13 || service.persistenceError.indexOf("host rejected") === -1)
        throw new Error("rejected scoped settings did not retain saved state and pending edits")
      console.log("MMW_QML_SCOPED_SETTINGS_OK")
      Qt.quit()
    }
  }
  Component.onCompleted: Qt.callLater(function() {
    service.configure({id: Model.PLUGIN_ID, count: 5, followOmarchy: false, _multiMonitorWorkspacesRevision: 4}, true)
    if (!service.shellEntry() || service.appliedRevision !== 4 || service.effectiveSettings.count !== 5)
      throw new Error("scoped snapshot lost legacy settings or revision authority")
    service.updateSettings({count: 12})
    savedCheck.start()
  })
}
