import Quickshell
import QtQuick
import "Model.js" as Model
ShellRoot {
  id: root
  property list<string> persistedMonitorPriority: ["DP-3", "DP-1"]
  Component.onCompleted: Qt.callLater(function() {
    var settings=Model.sanitizeSettings({count:"7",monitorPriority:["DP-3","DP-3","DP-1"]})
    if (settings.count !== 7 || settings.monitorPriority.join(",") !== "DP-3,DP-1") throw new Error("sanitization failed")
    if (Model.sanitizeSettings({monitorPriority:root.persistedMonitorPriority}).monitorPriority.join(",") !== "DP-3,DP-1") throw new Error("QML monitor priority reset")
    if (Model.workspaceIds(Model.bankIndex(settings,"DP-1",["DP-1","DP-3"]),7)[0] !== 8) throw new Error("bank calculation failed")
    var themed=Model.sanitizeSettings({workspaceGlyphs:{"1":"🎮","4":"","0":"bad","constructor":"bad"}})
    if (Model.labelFor(1,1,"hybrid",true,true,themed)!=="🎮" || Model.labelFor(4,4,"number",false,true,themed)!==""
        || Object.keys(themed.workspaceGlyphs).length!==2) throw new Error("workspace theme sanitization failed")
    for (var index=0; index<1000; index++) if (Model.scrollTarget(1,-1,[1,2,3],true) !== 3) throw new Error("navigation race")
    console.log("MMW_QML_MODEL_OK"); Qt.quit()
  })
}
