const assert = require("node:assert/strict")
const fs = require("node:fs")
const path = require("node:path")
const vm = require("node:vm")
const source = fs.readFileSync(path.join(__dirname,"..","Model.js"),"utf8").replace(/^\.pragma library\s*$/m,"")
const model={}; vm.createContext(model); vm.runInContext(source,model)
let seed=0x51f15e
const random=()=>{seed=(seed*1664525+1013904223)>>>0;return seed/0x100000000}
for(let iteration=0;iteration<5000;iteration++) {
  const count=Math.floor(random()*50)-10, monitors=Array.from({length:1+Math.floor(random()*8)},(_,i)=>`DP-${i+1}`)
  const clean=model.sanitizeSettings({count,monitorPriority:monitors.slice().reverse().concat(monitors),buttonWidth:random()*100-20,
    activeOpacity:random()*3-1,monitorBanks:Object.fromEntries(monitors.map(name=>[name,Math.floor(random()*4)]))})
  assert.ok(clean.count>=1&&clean.count<=20); assert.ok(clean.buttonWidth>=24&&clean.buttonWidth<=48); assert.ok(clean.activeOpacity>=.45&&clean.activeOpacity<=1)
  const assignments=model.assignedBankMap(clean,monitors)
  assert.equal(new Set(Object.values(assignments)).size,monitors.length,"duplicate overrides must be deconflicted")
  const banks=monitors.map(name=>model.workspaceIds(model.bankIndex(clean,name,monitors),clean.count))
  const flat=banks.flat(); assert.equal(new Set(flat).size,flat.length,"explicit banks must never overlap")
  for(const ids of banks) { assert.equal(ids.length,clean.count); for(let i=1;i<ids.length;i++) assert.equal(ids[i],ids[i-1]+1) }
  const active=flat[Math.floor(random()*flat.length)]
  assert.ok(flat.includes(model.scrollTarget(active,random()<.5?-1:1,flat,true)))
  const glyphInput={}; for(let id=1;id<=250;id++) glyphInput[String(id).padStart(random()<.25?3:1,"0")]=`G${id}`
  const glyphs=model.sanitizeSettings({workspaceGlyphs:glyphInput}).workspaceGlyphs
  assert.ok(Object.keys(glyphs).length<=200)
  for(const [id,glyph] of Object.entries(glyphs)) { assert.ok(Number(id)>=1&&Number(id)<=2000); assert.ok(glyph.length>0&&glyph.length<=8) }
}
console.log("Multi-monitor workspace randomized invariants passed")
