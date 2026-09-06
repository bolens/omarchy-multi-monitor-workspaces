const assert = require("node:assert/strict")
const fs = require("node:fs")
const os = require("node:os")
const path = require("node:path")
const { spawnSync } = require("node:child_process")
const root = path.join(__dirname, "..")
const runner = path.join(root, "tests/run_all.sh")
const invalid = spawnSync("bash", [runner, "--unknown"], { encoding: "utf8" })
assert.equal(invalid.status, 2)
const temporary = fs.mkdtempSync(path.join(os.tmpdir(), "mmw-runner-"))
try {
  for (const name of ["node", "python3"]) {
    fs.writeFileSync(path.join(temporary, name), "#!/bin/sh\nexit 0\n", { mode: 0o755 })
  }
  const result = spawnSync("bash", [runner, "--portable"], {
    encoding: "utf8",
    env: { ...process.env, PATH: `${temporary}:${process.env.PATH}`, QMLLINT: "/unavailable/qmllint", MMW_QML_TESTS: "always" },
  })
  assert.equal(result.status, 0, result.stderr)
  assert.match(result.stdout, /Portable validation passed/)
} finally {
  fs.rmSync(temporary, { recursive: true, force: true })
}
console.log("portable runner mode passed")
