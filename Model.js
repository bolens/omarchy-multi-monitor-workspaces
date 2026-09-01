.pragma library

var PLUGIN_ID = "io.github.bolens.multi-monitor-workspaces"
var LEGACY_IDS = ["io.github.derluke.dual-monitor-workspaces"]
var SETTINGS_VERSION = 1
var SETTING_KEYS = ["count","monitorPriority","monitorBanks","labelMode","activeGlyph","occupiedGlyph","emptyGlyph","workspaceGlyphs",
  "showEmpty","showTooltips","wrapScroll","clickAction","activeOpacity","occupiedOpacity","emptyOpacity","buttonWidth","horizontalMargin",
  "verticalPadding","activeColorRole","occupiedColorRole","emptyColorRole"]
var DEFAULTS = {
  count: 10, monitorPriority: [], monitorBanks: {}, labelMode: "number",
  activeGlyph: "󱓻", occupiedGlyph: "●", emptyGlyph: "○", workspaceGlyphs: {},
  showEmpty: true, showTooltips: true, wrapScroll: true, clickAction: "focus",
  activeOpacity: 1, occupiedOpacity: 0.82, emptyOpacity: 0.45,
  buttonWidth: 24, horizontalMargin: 6, verticalPadding: 6,
  activeColorRole: "accent", occupiedColorRole: "foreground", emptyColorRole: "muted"
}

function isObject(value) { return value !== null && typeof value === "object" && !Array.isArray(value) }
function boundedInteger(value, fallback, minimum, maximum) {
  var number = Number(value)
  if (!isFinite(number)) number = fallback
  return Math.max(minimum, Math.min(maximum, Math.round(number)))
}
function boundedNumber(value, fallback, minimum, maximum) {
  var number = Number(value)
  if (!isFinite(number)) number = fallback
  return Math.max(minimum, Math.min(maximum, number))
}
function enumValue(value, allowed, fallback) {
  var candidate = String(value || "")
  return allowed.indexOf(candidate) >= 0 ? candidate : fallback
}
function glyph(value, fallback) {
  var candidate = String(value === undefined || value === null ? "" : value).trim()
  return candidate ? candidate.slice(0, 8) : fallback
}
function isBoundedList(value) {
  if (!value || typeof value !== "object") return false
  var length=Number(value.length)
  return isFinite(length) && length>=0 && Math.floor(length)===length && length<=4096
}
function uniqueNames(value, limit) {
  if (!isBoundedList(value)) return []
  var result = []
  for (var index = 0; index < value.length && result.length < limit; index++) {
    var name = String(value[index] || "").trim().slice(0,128)
    if (name && result.indexOf(name) < 0) result.push(name)
  }
  return result
}
function uniqueMonitorNames(value) { return uniqueNames(value,64) }
function monitorBankMap(value) {
  var result = {}
  if (!isObject(value)) return result
  Object.keys(value).sort().slice(0,64).forEach(function(rawKey) {
    var key = String(rawKey || "").trim().slice(0,128)
    if (key && key!=="__proto__" && key!=="constructor" && key!=="prototype") result[key] = boundedInteger(value[rawKey], 0, 0, 99)
  })
  return result
}
function workspaceGlyphMap(value) {
  var result={}
  if (!isObject(value)) return result
  Object.keys(value).sort(function(left,right){
    var difference=Number(left)-Number(right)
    if (difference!==0) return difference
    var leftCanonical=left===String(Number(left)), rightCanonical=right===String(Number(right))
    return leftCanonical===rightCanonical ? left.localeCompare(right) : (leftCanonical ? -1 : 1)
  }).forEach(function(rawKey) {
    var id=Number(rawKey), candidate=String(value[rawKey]===undefined || value[rawKey]===null ? "" : value[rawKey]).trim()
    var key=String(id)
    if (Object.keys(result).length<200 && !Object.prototype.hasOwnProperty.call(result,key)
        && isFinite(id) && Math.round(id)===id && id>=1 && id<=2000 && candidate) result[key]=candidate.slice(0,8)
  })
  return result
}
function settingsPatch(value) {
  var result={}
  if (!isObject(value)) return result
  for (var index=0;index<SETTING_KEYS.length;index++) {
    var key=SETTING_KEYS[index]
    if (Object.prototype.hasOwnProperty.call(value,key)) result[key]=value[key]
  }
  return result
}
function mergePatchObjects(base, patch) {
  var result=settingsPatch(base), next=settingsPatch(patch), keys=Object.keys(next)
  for (var index=0;index<keys.length;index++) result[keys[index]]=next[keys[index]]
  return result
}
function mergeSettings(base, patch) {
  var source=sanitizeSettings(base), changes=settingsPatch(patch), merged={}
  for (var index=0;index<SETTING_KEYS.length;index++) {
    var key=SETTING_KEYS[index]
    merged[key]=Object.prototype.hasOwnProperty.call(changes,key) ? changes[key] : source[key]
  }
  return sanitizeSettings(merged)
}
function sanitizeSettings(value) {
  var source = isObject(value) ? value : {}
  return {
    count: boundedInteger(source.count, DEFAULTS.count, 1, 20),
    monitorPriority: uniqueMonitorNames(source.monitorPriority),
    monitorBanks: monitorBankMap(source.monitorBanks),
    labelMode: enumValue(source.labelMode, ["number", "global", "glyph", "hybrid"], DEFAULTS.labelMode),
    activeGlyph: glyph(source.activeGlyph, DEFAULTS.activeGlyph),
    occupiedGlyph: glyph(source.occupiedGlyph, DEFAULTS.occupiedGlyph),
    emptyGlyph: glyph(source.emptyGlyph, DEFAULTS.emptyGlyph),
    workspaceGlyphs: workspaceGlyphMap(source.workspaceGlyphs),
    showEmpty: source.showEmpty !== false,
    showTooltips: source.showTooltips !== false,
    wrapScroll: source.wrapScroll !== false,
    clickAction: enumValue(source.clickAction, ["focus", "move", "move-silent"], DEFAULTS.clickAction),
    activeOpacity: boundedNumber(source.activeOpacity, DEFAULTS.activeOpacity, 0.45, 1),
    occupiedOpacity: boundedNumber(source.occupiedOpacity, DEFAULTS.occupiedOpacity, 0.45, 1),
    emptyOpacity: boundedNumber(source.emptyOpacity, DEFAULTS.emptyOpacity, 0.45, 1),
    buttonWidth: boundedInteger(source.buttonWidth, DEFAULTS.buttonWidth, 24, 48),
    horizontalMargin: boundedInteger(source.horizontalMargin, DEFAULTS.horizontalMargin, 0, 20),
    verticalPadding: boundedInteger(source.verticalPadding, DEFAULTS.verticalPadding, 0, 16),
    activeColorRole: enumValue(source.activeColorRole, ["accent","foreground","muted","urgent"], DEFAULTS.activeColorRole),
    occupiedColorRole: enumValue(source.occupiedColorRole, ["accent","foreground","muted","urgent"], DEFAULTS.occupiedColorRole),
    emptyColorRole: enumValue(source.emptyColorRole, ["accent","foreground","muted","urgent"], DEFAULTS.emptyColorRole)
  }
}
function sortedMonitorNames(value) { return uniqueNames(value,100).sort() }
function assignedBankMap(settings, connectedNames) {
  var clean=sanitizeSettings(settings), connected=sortedMonitorNames(connectedNames), order=[]
  for (var priorityIndex=0; priorityIndex<clean.monitorPriority.length; priorityIndex++) {
    var priorityName=clean.monitorPriority[priorityIndex]
    if (connected.indexOf(priorityName)>=0 && order.indexOf(priorityName)<0) order.push(priorityName)
  }
  for (var connectedIndex=0; connectedIndex<connected.length; connectedIndex++)
    if (order.indexOf(connected[connectedIndex])<0) order.push(connected[connectedIndex])
  var result={}, used={}
  for (var index=0; index<order.length; index++) {
    var name=order[index], desired=Object.prototype.hasOwnProperty.call(clean.monitorBanks,name)
      ? clean.monitorBanks[name] : clean.monitorPriority.indexOf(name)
    if (desired<0) desired=index
    if (used[desired]===true) { desired=0; while (used[desired]===true) desired++ }
    result[name]=desired; used[desired]=true
  }
  return result
}
function bankIndex(settings, screenName, connectedNames) {
  var name = String(screenName || "").trim()
  var assignments=assignedBankMap(settings,connectedNames)
  if (Object.prototype.hasOwnProperty.call(assignments,name)) return assignments[name]
  var clean=sanitizeSettings(settings)
  if (Object.prototype.hasOwnProperty.call(clean.monitorBanks,name)) return clean.monitorBanks[name]
  var used={}, keys=Object.keys(assignments)
  for (var index=0; index<keys.length; index++) used[assignments[keys[index]]]=true
  var fallback=0; while (used[fallback]===true) fallback++
  return fallback
}
function workspaceIds(bank, count) {
  var safeBank = boundedInteger(bank, 0, 0, 99)
  var safeCount = boundedInteger(count, DEFAULTS.count, 1, 20)
  var result = [], start = safeBank * safeCount + 1
  for (var id = start; id < start + safeCount; id++) result.push(id)
  return result
}
function localNumber(id, bank, count) { return Number(id) - boundedInteger(bank, 0, 0, 99) * boundedInteger(count, DEFAULTS.count, 1, 20) }
function labelFor(id, local, mode, active, occupied, settings) {
  var clean = isObject(settings) ? settings : DEFAULTS
  var custom=workspaceGlyphFor(clean,id)
  if (custom) return custom
  if (mode === "global") return String(id)
  if (mode === "glyph") return active ? glyph(clean.activeGlyph,DEFAULTS.activeGlyph) : (occupied ? glyph(clean.occupiedGlyph,DEFAULTS.occupiedGlyph) : glyph(clean.emptyGlyph,DEFAULTS.emptyGlyph))
  if (mode === "hybrid" && active) return glyph(clean.activeGlyph,DEFAULTS.activeGlyph)
  return local === 10 ? "0" : String(local)
}
function workspaceGlyphFor(settings, id) {
  var values=isObject(settings) && isObject(settings.workspaceGlyphs) ? settings.workspaceGlyphs : ({})
  var candidate=values[String(Number(id))]
  return candidate===undefined || candidate===null ? "" : String(candidate).trim().slice(0,8)
}
function colorRoleFor(mode, active, occupied, settings) {
  var clean=isObject(settings) ? settings : DEFAULTS
  if (active || (mode==="hybrid" && occupied)) return clean.activeColorRole || DEFAULTS.activeColorRole
  return occupied ? (clean.occupiedColorRole || DEFAULTS.occupiedColorRole) : (clean.emptyColorRole || DEFAULTS.emptyColorRole)
}
function opacityFor(mode, active, occupied, settings) {
  var clean=isObject(settings) ? settings : DEFAULTS
  if (active || (mode==="hybrid" && occupied)) return boundedNumber(clean.activeOpacity,DEFAULTS.activeOpacity,.45,1)
  return occupied ? boundedNumber(clean.occupiedOpacity,DEFAULTS.occupiedOpacity,.45,1) : boundedNumber(clean.emptyOpacity,DEFAULTS.emptyOpacity,.45,1)
}
function visibleWorkspaceIds(ids, occupiedById, activeId, showEmpty) {
  if (showEmpty) return ids.slice()
  return ids.filter(function(id) { return id === activeId || occupiedById[id] === true })
}
function scrollTarget(activeId, direction, ids, wrap) {
  if (!ids.length) return 0
  var index = ids.indexOf(activeId), step = direction < 0 ? -1 : 1
  if (index < 0) return step < 0 ? ids[ids.length - 1] : ids[0]
  var next = index + step
  if (wrap) next = (next + ids.length) % ids.length
  else next = Math.max(0, Math.min(ids.length - 1, next))
  return ids[next]
}
function entryId(entry) { return typeof entry === "string" ? entry : (isObject(entry) ? String(entry.id || "") : "") }
function migrateConfig(config) {
  if (!isObject(config) || !isObject(config.bar) || !isObject(config.bar.layout)) return {changed:false, version:SETTINGS_VERSION}
  var changed = false
  ;["left","center","right"].forEach(function(section) {
    var entries = config.bar.layout[section]
    if (!Array.isArray(entries)) return
    for (var index = 0; index < entries.length; index++) {
      if (LEGACY_IDS.indexOf(entryId(entries[index])) < 0 && entryId(entries[index]) !== PLUGIN_ID) continue
      var entry = typeof entries[index] === "string" ? {id:PLUGIN_ID} : entries[index]
      if (entry.id !== PLUGIN_ID) { entry.id = PLUGIN_ID; changed = true }
      var clean = sanitizeSettings(entry)
      Object.keys(clean).forEach(function(key) {
        if (JSON.stringify(entry[key]) !== JSON.stringify(clean[key])) { entry[key] = clean[key]; changed = true }
      })
      if (entry._multiMonitorWorkspacesSettingsVersion !== SETTINGS_VERSION) {
        entry._multiMonitorWorkspacesSettingsVersion = SETTINGS_VERSION; changed = true
      }
      entries[index] = entry
    }
  })
  return {changed:changed, version:SETTINGS_VERSION}
}
