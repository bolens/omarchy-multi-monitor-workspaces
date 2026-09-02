pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import qs.Commons
import qs.Ui

Item {
  id: root
  required property var controller
  property string page: "general"
  readonly property var service: controller.workspaceService
  readonly property var values: controller.effectiveSettings
  readonly property Item initialFocusTarget: generalTab
  readonly property real contentHeight: settingsColumn.implicitHeight
  readonly property real contentY: flick.contentY
  readonly property real maximumContentY: Math.max(0, flick.contentHeight - flick.height)
  implicitHeight: Style.space(560)

  function patch(key, value) { var update={}; update[key]=value; if (service) service.updateSettings(update) }
  function setMonitorBank(name, bank) {
    var banks=Object.assign({},root.values.monitorBanks), key=String(name || "").trim()
    if (!key) return
    banks[key]=bank
    patch("monitorBanks",banks)
  }
  function setWorkspaceGlyph(workspaceId, value) {
    var glyphs=Object.assign({},root.values.workspaceGlyphs), key=String(workspaceId), candidate=String(value || "").trim()
    if (candidate) glyphs[key]=candidate
    else delete glyphs[key]
    patch("workspaceGlyphs",glyphs)
  }
  function applyScroll(position) {
    var requested=String(position || "top")
    flick.contentY=requested === "bottom" ? maximumContentY : (requested === "middle" ? maximumContentY/2 : 0)
    return JSON.stringify({page:page,y:flick.contentY,maximum:maximumContentY})
  }
  function enumIndex(values, current) { var index=values.indexOf(current); return index < 0 ? 0 : index }
  onPageChanged: Qt.callLater(function(){root.applyScroll("top")})

  ColumnLayout {
    anchors.fill: parent
    spacing: Style.space(8)
    Text { Layout.fillWidth:true; text:"Multi-Monitor Workspaces"; textFormat:Text.PlainText; color:Color.popups.text; font.family:Style.font.family; font.pixelSize:Style.font.title; font.bold:true }
    Text { Layout.fillWidth:true; text:"" + root.controller.screenName + " uses bank " + (root.controller.monitorBankIndex + 1) + ". Settings apply to every monitor.";
      textFormat:Text.PlainText; color:Color.muted; font.family:Style.font.family; font.pixelSize:Style.font.bodySmall; wrapMode:Text.WordWrap }
    RowLayout {
      Layout.fillWidth:true; spacing:Style.space(6)
      Button { id:generalTab; text:"Behavior"; active:root.page === "general"; onClicked:root.page="general" }
      Button { text:"Appearance"; active:root.page === "appearance"; onClicked:root.page="appearance" }
      Item { Layout.fillWidth:true }
    }
    Rectangle {
      Layout.fillWidth:true; Layout.fillHeight:true; radius:Style.space(8); color:Qt.lighter(Color.popups.background,1.08); clip:true
      Flickable {
        id:flick; anchors.fill:parent; anchors.margins:Style.space(10); contentWidth:width; contentHeight:settingsColumn.implicitHeight
        clip:true; boundsBehavior:Flickable.StopAtBounds
        Controls.ScrollBar.vertical: Controls.ScrollBar { policy:Controls.ScrollBar.AsNeeded }
        ColumnLayout {
          id:settingsColumn; width:flick.width; spacing:Style.space(10)
          Text { Layout.fillWidth:true; text:root.page === "general" ? "Workspace behavior" : "Workspace appearance"; color:Color.popups.text;
            font.family:Style.font.family; font.pixelSize:Style.font.body; font.bold:true }

          ColumnLayout {
            visible:root.page === "general"; Layout.fillWidth:true; spacing:Style.space(10)
            RowLayout {
              Layout.fillWidth:true
              ColumnLayout { Layout.fillWidth:true; spacing:1
                Text { text:"Workspaces per monitor"; color:Color.popups.text; font.family:Style.font.family; font.pixelSize:Style.font.bodySmall }
                Text { Layout.fillWidth:true; text:"Each monitor receives a non-overlapping bank of this size."; color:Color.muted; font.family:Style.font.family; font.pixelSize:Style.font.caption; wrapMode:Text.WordWrap }
              }
              Controls.SpinBox { from:1; to:20; value:root.values.count; editable:true; onValueModified:root.patch("count",value) }
            }
            RowLayout {
              Layout.fillWidth:true
              ColumnLayout { Layout.fillWidth:true; spacing:1
                Text { text:"Workspace labels"; color:Color.popups.text; font.family:Style.font.family; font.pixelSize:Style.font.bodySmall }
                Text { Layout.fillWidth:true; text:"Local numbers, global IDs, or state glyphs."; color:Color.muted; font.family:Style.font.family; font.pixelSize:Style.font.caption; wrapMode:Text.WordWrap }
              }
              Controls.ComboBox { model:["number","hybrid","global","glyph"]; currentIndex:root.enumIndex(model,root.values.labelMode); onActivated:(index) => root.patch("labelMode",model[index]) }
            }
            RowLayout {
              Layout.fillWidth:true
              ColumnLayout { Layout.fillWidth:true; spacing:1
                Text { text:"Primary click"; color:Color.popups.text; font.family:Style.font.family; font.pixelSize:Style.font.bodySmall }
                Text { Layout.fillWidth:true; text:"Focus a workspace or move the active window there."; color:Color.muted; font.family:Style.font.family; font.pixelSize:Style.font.caption; wrapMode:Text.WordWrap }
              }
              Controls.ComboBox { model:["focus","move","move-silent"]; currentIndex:root.enumIndex(model,root.values.clickAction); onActivated:(index) => root.patch("clickAction",model[index]) }
            }
            Controls.CheckBox { text:"Show empty workspaces"; checked:root.values.showEmpty; onToggled:root.patch("showEmpty",checked) }
            Controls.CheckBox { text:"Wrap wheel navigation at bank edges"; checked:root.values.wrapScroll; onToggled:root.patch("wrapScroll",checked) }
            Controls.CheckBox { text:"Show workspace tooltips"; checked:root.values.showTooltips; onToggled:root.patch("showTooltips",checked) }
            Rectangle { Layout.fillWidth:true; implicitHeight:1; color:Color.muted; opacity:.3 }
            Text { Layout.fillWidth:true; text:"Monitor mapping"; color:Color.popups.text; font.family:Style.font.family; font.pixelSize:Style.font.bodySmall; font.bold:true }
            Text { Layout.fillWidth:true; text:"Connected monitors are assigned deterministically by explicit overrides, then priority order, then output name. Current: "
                + (root.service ? root.service.monitorNames().map(function(name){return name+" → "+(root.service.workspaceIdsFor(name)[0])+"–"+root.service.workspaceIdsFor(name).slice(-1)[0]}).join(" · ") : "unavailable");
              textFormat:Text.PlainText; color:Color.muted; font.family:Style.font.family; font.pixelSize:Style.font.caption; wrapMode:Text.WordWrap }
            Repeater {
              model: {
                if (!root.service) return []
                root.service.topologySerial
                return root.service.monitorNames()
              }
              RowLayout {
                id: monitorRow
                required property string modelData
                Layout.fillWidth:true
                ColumnLayout { Layout.fillWidth:true; spacing:1
                  Text { text:monitorRow.modelData; color:Color.popups.text; font.family:Style.font.family; font.pixelSize:Style.font.bodySmall }
                  Text { Layout.fillWidth:true; text:"First workspace " + (root.service.workspaceIdsFor(monitorRow.modelData)[0]); color:Color.muted; font.family:Style.font.family; font.pixelSize:Style.font.caption; wrapMode:Text.WordWrap }
                }
                Text { text:"Bank"; color:Color.muted; font.family:Style.font.family; font.pixelSize:Style.font.caption }
                Controls.SpinBox { from:0; to:99; value:Math.floor((root.service.workspaceIdsFor(monitorRow.modelData)[0]-1)/root.values.count); onValueModified:root.setMonitorBank(monitorRow.modelData,value) }
              }
            }
          }

          ColumnLayout {
            visible:root.page === "appearance"; Layout.fillWidth:true; spacing:Style.space(10)
            RowLayout { Layout.fillWidth:true; Text { Layout.fillWidth:true; text:"Active glyph"; color:Color.popups.text; font.family:Style.font.family }
              Controls.TextField { text:root.values.activeGlyph; maximumLength:8; onEditingFinished:root.patch("activeGlyph",text) } }
            RowLayout { Layout.fillWidth:true; Text { Layout.fillWidth:true; text:"Occupied glyph"; color:Color.popups.text; font.family:Style.font.family }
              Controls.TextField { text:root.values.occupiedGlyph; maximumLength:8; onEditingFinished:root.patch("occupiedGlyph",text) } }
            RowLayout { Layout.fillWidth:true; Text { Layout.fillWidth:true; text:"Empty glyph"; color:Color.popups.text; font.family:Style.font.family }
              Controls.TextField { text:root.values.emptyGlyph; maximumLength:8; onEditingFinished:root.patch("emptyGlyph",text) } }
            Text { Layout.fillWidth:true; text:"Glyphs are used when Workspace labels is set to glyph."; color:Color.muted; font.family:Style.font.family; font.pixelSize:Style.font.caption; wrapMode:Text.WordWrap }
            Rectangle { Layout.fillWidth:true; implicitHeight:1; color:Color.muted; opacity:.3 }
            Text { Layout.fillWidth:true; text:"Workspace themes · " + root.controller.screenName; color:Color.popups.text; font.family:Style.font.family; font.pixelSize:Style.font.bodySmall; font.bold:true }
            Text { Layout.fillWidth:true; text:"Optional glyphs use global workspace IDs and override the normal label in every mode. Leave a field empty to use the selected label mode."; color:Color.muted; font.family:Style.font.family; font.pixelSize:Style.font.caption; wrapMode:Text.WordWrap }
            GridLayout {
              id:workspaceGlyphGrid
              Layout.fillWidth:true
              columns:2
              columnSpacing:Style.space(10)
              rowSpacing:Style.space(6)
              uniformCellWidths:true
              Repeater {
                model:root.controller.bankWorkspaceIds
                RowLayout {
                  id: glyphRow
                  required property int modelData
                  Layout.fillWidth:true
                  Layout.minimumHeight:Style.space(36)
                  spacing:Style.space(5)
                  Text {
                    Layout.fillWidth:true
                    text:"Workspace " + glyphRow.modelData
                    color:Color.popups.text
                    font.family:Style.font.family
                    font.pixelSize:Style.font.caption
                    elide:Text.ElideRight
                  }
                  Controls.TextField {
                    objectName:"workspaceGlyphEditor-"+glyphRow.modelData
                    Layout.preferredWidth:Style.space(72)
                    Accessible.name:"Glyph for workspace " + glyphRow.modelData
                    text:root.values.workspaceGlyphs[String(glyphRow.modelData)] || ""
                    placeholderText:"Default"
                    maximumLength:8
                    onEditingFinished:root.setWorkspaceGlyph(glyphRow.modelData,text)
                  }
                }
              }
            }
            RowLayout { Layout.fillWidth:true; Text { Layout.fillWidth:true; text:"Button width"; color:Color.popups.text; font.family:Style.font.family }
              Controls.SpinBox { from:24; to:48; value:root.values.buttonWidth; onValueModified:root.patch("buttonWidth",value) } }
            RowLayout { Layout.fillWidth:true; Text { Layout.fillWidth:true; text:"Horizontal margin"; color:Color.popups.text; font.family:Style.font.family }
              Controls.SpinBox { from:0; to:20; value:root.values.horizontalMargin; onValueModified:root.patch("horizontalMargin",value) } }
            RowLayout { Layout.fillWidth:true; Text { Layout.fillWidth:true; text:"Vertical padding"; color:Color.popups.text; font.family:Style.font.family }
              Controls.SpinBox { from:0; to:16; value:root.values.verticalPadding; onValueModified:root.patch("verticalPadding",value) } }
            RowLayout { Layout.fillWidth:true; Text { Layout.fillWidth:true; text:"Active color"; color:Color.popups.text; font.family:Style.font.family }
              Controls.ComboBox { model:["accent","foreground","muted","urgent"]; currentIndex:root.enumIndex(model,root.values.activeColorRole); onActivated:(index) => root.patch("activeColorRole",model[index]) } }
            RowLayout { Layout.fillWidth:true; Text { Layout.fillWidth:true; text:"Occupied color"; color:Color.popups.text; font.family:Style.font.family }
              Controls.ComboBox { model:["accent","foreground","muted","urgent"]; currentIndex:root.enumIndex(model,root.values.occupiedColorRole); onActivated:(index) => root.patch("occupiedColorRole",model[index]) } }
            RowLayout { Layout.fillWidth:true; Text { Layout.fillWidth:true; text:"Empty color"; color:Color.popups.text; font.family:Style.font.family }
              Controls.ComboBox { model:["accent","foreground","muted","urgent"]; currentIndex:root.enumIndex(model,root.values.emptyColorRole); onActivated:(index) => root.patch("emptyColorRole",model[index]) } }
            Text { Layout.fillWidth:true; text:"Opacity"; color:Color.popups.text; font.family:Style.font.family; font.bold:true }
            RowLayout { Layout.fillWidth:true; Text { text:"Active"; color:Color.popups.text; font.family:Style.font.family; Layout.preferredWidth:Style.space(70) }
              Controls.Slider { Layout.fillWidth:true; from:.45; to:1; stepSize:.05; value:root.values.activeOpacity; onMoved:root.patch("activeOpacity",value) }
              Text { text:Math.round(root.values.activeOpacity*100)+"%"; color:Color.muted; Layout.preferredWidth:Style.space(40) } }
            RowLayout { Layout.fillWidth:true; Text { text:"Occupied"; color:Color.popups.text; font.family:Style.font.family; Layout.preferredWidth:Style.space(70) }
              Controls.Slider { Layout.fillWidth:true; from:.45; to:1; stepSize:.05; value:root.values.occupiedOpacity; onMoved:root.patch("occupiedOpacity",value) }
              Text { text:Math.round(root.values.occupiedOpacity*100)+"%"; color:Color.muted; Layout.preferredWidth:Style.space(40) } }
            RowLayout { Layout.fillWidth:true; Text { text:"Empty"; color:Color.popups.text; font.family:Style.font.family; Layout.preferredWidth:Style.space(70) }
              Controls.Slider { Layout.fillWidth:true; from:.45; to:1; stepSize:.05; value:root.values.emptyOpacity; onMoved:root.patch("emptyOpacity",value) }
              Text { text:Math.round(root.values.emptyOpacity*100)+"%"; color:Color.muted; Layout.preferredWidth:Style.space(40) } }
          }
        }
      }
    }
    Text { Layout.fillWidth:true; visible:root.service && root.service.lastError !== ""; text:root.service ? root.service.lastError : ""; color:Color.urgent;
      font.family:Style.font.family; font.pixelSize:Style.font.caption; wrapMode:Text.WordWrap }
    RowLayout { Layout.fillWidth:true; Item { Layout.fillWidth:true }
      Button { text:"Reset"; onClicked:if(root.service) root.service.resetSettings() }
      Button { text:"Close"; onClicked:root.controller.closeSettings() }
    }
  }
}
