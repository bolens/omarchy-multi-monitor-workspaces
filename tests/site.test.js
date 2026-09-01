const assert=require("node:assert/strict"),fs=require("node:fs")
const cssBlock=(source,marker)=>{const start=source.indexOf(marker);assert.notEqual(start,-1,`missing ${marker}`);const open=source.indexOf("{",start);let depth=0;for(let i=open;i<source.length;i++){if(source[i]==="{")depth++;else if(source[i]==="}"&&--depth===0)return source.slice(open+1,i)}assert.fail(`unclosed ${marker}`)}
assert.ok(fs.statSync("scripts/build-site.sh").mode&0o100,"site builder must remain executable")
const html=fs.readFileSync("docs/index.html","utf8"),css=fs.readFileSync("docs/styles.css","utf8"),responsive=fs.readFileSync("docs/responsive.css","utf8"),themeCss=fs.readFileSync("docs/theme.css","utf8"),themeJs=fs.readFileSync("docs/theme.js","utf8")
const notFound=fs.readFileSync("docs/404.html","utf8")
for(const id of ["main","model","features","settings","install"]) assert.ok(html.includes(`id="${id}"`),`missing section ${id}`)
for(const asset of ["styles.css","responsive.css","theme.css","theme.js","site.js","favicon.svg","preview.png"]) assert.ok(html.includes(asset),`missing asset ${asset}`)
for(const theme of ["github-light","catppuccin-latte","solarized-light"]) assert.ok(html.includes(`value="${theme}"`),`missing ${theme} option`)
assert.match(html,/prefers-color-scheme: light/);assert.match(html,/\? "github-light" : "workspaces"/)
assert.match(themeCss,/\[data-theme="github-light"\]\{color-scheme:light/);assert.match(themeJs,/localStorage\.setItem/)
assert.match(notFound,/prefers-color-scheme: light/);assert.match(notFound,/multi-monitor-workspaces-site-theme/)
for(const term of ["1 → 100 monitors","Atomic topology","per-workspace glyph","Race-safe persistence"]) assert.match(html,new RegExp(term,"i"))
assert.match(html,/\{\{VERSION\}\}/); assert.match(html,/class="skip"/); assert.match(css,/prefers-reduced-motion/)
assert.match(css,/#55e6dd/i); assert.match(css,/#ff775f/i)
const mobileCss=cssBlock(responsive,"@media (max-width: 820px)")
assert.match(mobileCss,/grid-template-columns:\s*minmax\(0, 1fr\)/)
assert.match(mobileCss,/\.install > \*\s*\{\s*min-width:\s*0/)
const channel=v=>{v/=255;return v<=.04045?v/12.92:((v+.055)/1.055)**2.4}
const luminance=hex=>{const rgb=hex.match(/[\da-f]{2}/gi).map(v=>channel(parseInt(v,16)));return .2126*rgb[0]+.7152*rgb[1]+.0722*rgb[2]}
const contrast=(a,b)=>(Math.max(luminance(a),luminance(b))+.05)/(Math.min(luminance(a),luminance(b))+.05)
const installKicker=[...css.matchAll(/\.install \.kicker\{color:#([\da-f]{6})/gi)].at(-1)?.[1]
const installCopy=responsive.match(/\.install p\s*\{\s*color:\s*#([\da-f]{6})/i)?.[1]
const coral=css.match(/--coral:#([\da-f]{6})/i)?.[1]
assert.ok(installKicker&&coral&&contrast(installKicker,coral)>=4.5,"install kicker must meet WCAG AA contrast")
assert.ok(installCopy&&coral&&contrast(installCopy,coral)>=4.5,"install copy must meet WCAG AA contrast")
const image=fs.readFileSync("preview.png"); assert.equal(image.subarray(1,4).toString(),"PNG")
assert.equal((html.match(/<h1/g)||[]).length,1); assert.equal((html.match(/data-copy/g)||[]).length,1)
console.log("Multi-Monitor Workspaces Pages structure passed")
