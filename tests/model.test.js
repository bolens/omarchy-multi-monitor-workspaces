const assert = require("node:assert/strict")
const fs = require("node:fs")
const path = require("node:path")
const vm = require("node:vm")

const source = fs.readFileSync(path.join(__dirname, "..", "Model.js"), "utf8").replace(/^\.pragma library\s*$/m, "")
const model = {}
vm.createContext(model)
vm.runInContext(source, model)

assert.equal(model.PLUGIN_ID, "io.github.bolens.multi-monitor-workspaces")
assert.equal(model.SETTINGS_VERSION, 1)

const defaults = model.sanitizeSettings({})
assert.equal(defaults.count, 10)
assert.equal(defaults.labelMode, "number")
assert.equal(defaults.clickAction, "focus")
assert.deepEqual(Array.from(defaults.monitorPriority), [])
assert.deepEqual(JSON.parse(JSON.stringify(defaults.workspaceGlyphs)), {})

const dirty = model.sanitizeSettings({
  count: 99, monitorPriority: [" DP-3 ", "DP-1", "DP-3", ""],
  monitorBanks: {" DP-3 ": 4, "": 2, "DP-1": -8}, labelMode: "bad",
  activeGlyph: "  A ", occupiedGlyph: "", emptyGlyph: " E ",
  activeOpacity: 9, occupiedOpacity: -1, emptyOpacity: "bad",
  buttonWidth: 999, horizontalMargin: -1, verticalPadding: 100,
  showEmpty: false, showTooltips: false, wrapScroll: false
  , workspaceGlyphs: {"1":"  🎮 ","04":"","0":"bad","-1":"bad","no":"bad","3":""}
})
assert.equal(dirty.count, 20)
assert.deepEqual(Array.from(dirty.monitorPriority), ["DP-3", "DP-1"])
assert.deepEqual(JSON.parse(JSON.stringify(dirty.monitorBanks)), {"DP-1": 0, "DP-3": 4})
assert.equal(dirty.labelMode, "number")
assert.equal(dirty.activeGlyph, "A")
assert.equal(dirty.occupiedGlyph, "●")
assert.equal(dirty.activeOpacity, 1)
assert.equal(dirty.occupiedOpacity, 0.45)
assert.equal(dirty.emptyOpacity, 0.45)
assert.equal(dirty.buttonWidth, 48)
assert.deepEqual(JSON.parse(JSON.stringify(dirty.workspaceGlyphs)), {"1":"🎮","4":""})

assert.equal(model.bankIndex(defaults, "DP-3", ["DP-1", "DP-3"]), 1)
assert.equal(model.bankIndex({monitorPriority:["DP-3"]}, "DP-3", ["DP-1", "DP-3"]), 0)
assert.equal(model.bankIndex({monitorBanks:{"DP-3":7}}, "DP-3", []), 7)
assert.equal(model.bankIndex(defaults, "unknown", ["DP-1", "DP-3"]), 2)
assert.deepEqual(JSON.parse(JSON.stringify(model.assignedBankMap({monitorBanks:{"DP-1":2,"DP-3":2}},["DP-3","DP-1"]))),
  {"DP-1":2,"DP-3":0}, "duplicate explicit banks must resolve deterministically without overlap")
assert.deepEqual(JSON.parse(JSON.stringify(model.assignedBankMap({monitorPriority:["DP-3","DP-1"]},["DP-1","DP-3"]))),
  {"DP-1":1,"DP-3":0})
const hotplugNames = Array.from({length:100}, (_,index) => `HOTPLUG-${String(index+1).padStart(3,"0")}`)
for (const attachedCount of [1,2,3,8,16,32,64,100]) {
  const attached=hotplugNames.slice(0,attachedCount), reversed=attached.slice().reverse()
  const forward=model.assignedBankMap(defaults,attached), reordered=model.assignedBankMap(defaults,reversed)
  assert.deepEqual(JSON.parse(JSON.stringify(reordered)),JSON.parse(JSON.stringify(forward)),"enumeration order changed automatic banks")
  assert.equal(Object.keys(forward).length,attachedCount,"bank map did not scale to the attached monitor count")
  assert.equal(new Set(Object.values(forward)).size,attachedCount,"hotplug allocation overlapped banks")
}
const unplugged=model.assignedBankMap(defaults,["HOTPLUG-001","HOTPLUG-003"])
assert.deepEqual(JSON.parse(JSON.stringify(unplugged)),{"HOTPLUG-001":0,"HOTPLUG-003":1},"detached output retained a bank")
assert.deepEqual(JSON.parse(JSON.stringify(model.assignedBankMap(defaults,["HOTPLUG-003","HOTPLUG-001"]))),JSON.parse(JSON.stringify(unplugged)),
  "reattach order changed the same connected-set allocation")
assert.equal(model.bankIndex({monitorPriority:["DP-1","DP-3"]},"DP-1",["HDMI-A-1","DP-1","DP-3"]),0,
  "attaching an unlisted monitor displaced an explicit priority bank")
assert.deepEqual(Array.from(model.workspaceIds(1, 5)), [6, 7, 8, 9, 10])
assert.equal(model.localNumber(10, 1, 5), 5)
assert.equal(model.labelFor(10, 5, "number", false, false, defaults), "5")
assert.equal(model.labelFor(10, 5, "global", false, false, defaults), "10")
assert.equal(model.labelFor(10, 5, "glyph", true, true, defaults), defaults.activeGlyph)
assert.equal(model.labelFor(10, 5, "hybrid", true, true, defaults), defaults.activeGlyph)
assert.equal(model.labelFor(10, 5, "hybrid", false, true, defaults), "5")
assert.equal(model.labelFor(10, 5, "hybrid", false, false, defaults), "5")
assert.equal(model.colorRoleFor("hybrid", true, false, defaults), defaults.activeColorRole)
assert.equal(model.colorRoleFor("hybrid", false, true, defaults), defaults.activeColorRole)
assert.equal(model.colorRoleFor("hybrid", false, false, defaults), defaults.emptyColorRole)
assert.equal(model.opacityFor("hybrid", false, true, defaults), 1)
const themed = model.sanitizeSettings({workspaceGlyphs:{"1":"🎮","4":""}})
assert.equal(model.workspaceGlyphFor(themed, 1), "🎮")
assert.equal(model.labelFor(1, 1, "number", false, false, themed), "🎮")
assert.equal(model.labelFor(4, 4, "hybrid", false, true, themed), "")
assert.equal(model.labelFor(2, 2, "hybrid", false, false, themed), "2")
assert.deepEqual(JSON.parse(JSON.stringify(model.settingsPatch({labelMode:"glyph",unknown:true,"__proto__":{polluted:true}}))), {labelMode:"glyph"})
assert.deepEqual(JSON.parse(JSON.stringify(model.mergeSettings({count:5,labelMode:"number"},{labelMode:"glyph"}))).count, 5)
assert.equal(model.mergeSettings({count:5,labelMode:"number"},{labelMode:"glyph"}).labelMode, "glyph")
const manyGlyphs={}; for (let id=1;id<=500;id++) manyGlyphs[id]=String(id)
assert.equal(Object.keys(model.sanitizeSettings({workspaceGlyphs:manyGlyphs}).workspaceGlyphs).length, 200)
assert.deepEqual(JSON.parse(JSON.stringify(model.sanitizeSettings({monitorBanks:{"__proto__":3,"constructor":4,"DP-1":0}}).monitorBanks)), {"DP-1":0})

assert.deepEqual(Array.from(model.visibleWorkspaceIds([1, 2, 3], {1:true}, 2, false)), [1, 2],
  "active workspace remains visible even when empty workspaces are hidden")
assert.equal(model.scrollTarget(1, -1, [1,2,3], true), 3)
assert.equal(model.scrollTarget(3, 1, [1,2,3], false), 3)

const oldConfig = {bar:{layout:{left:[{id:"io.github.derluke.dual-monitor-workspaces", count:8,
  monitorPriority:["DP-1","DP-3"]}]}}}
const migration = model.migrateConfig(oldConfig)
assert.equal(migration.changed, true)
assert.equal(oldConfig.bar.layout.left[0].id, model.PLUGIN_ID)
assert.equal(oldConfig.bar.layout.left[0].count, 8)
assert.equal(oldConfig.bar.layout.left[0]._multiMonitorWorkspacesSettingsVersion, 1)
assert.equal(model.migrateConfig(oldConfig).changed, false)

console.log("Multi-monitor workspace model tests passed")
