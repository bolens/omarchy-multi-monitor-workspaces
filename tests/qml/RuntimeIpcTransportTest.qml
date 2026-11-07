pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io


ShellRoot {
    id: root
    readonly property string configPath: Quickshell.shellPath("RuntimeIpcTransportTest.qml")
    readonly property string executable: String(Quickshell.env("QUICKSHELL_BIN") || "/usr/bin/quickshell")
    property bool announced: false
    property bool started: false
    property bool finished: false
    property int step: 0
    readonly property string targetName: "multi-monitor-workspaces"
    readonly property string requiredSignature: "function activate(screen: string, workspace: int, action: string): string"
    readonly property var calls: [
        {show:true}, {method:"status",args:[],validator:"status"},
        {method:"registeredMonitors",args:[],expected:'["DP-1"]'},
        {method:"workspaceIds",args:["DP-1"],expected:'[1,2,3]'},
        {method:"activate",args:["DP-1","2","focus"],expected:"activated"},
        {method:"activate",args:["DP-1","not-an-int","focus"],code:0,
            expected:'Unable to parse argument 2 as "int". Provided argument: "not-an-int"\nFunction definition: function activate(screen: string, workspace: int, action: string): string'},
        {method:"activate",args:["DP-1","2"],code:0,
            expected:'Too few arguments provided (3 required but 2 were provided.)\nFunction definition: function activate(screen: string, workspace: int, action: string): string'},
        {method:"__ci_missing__",args:[],code:0,expected:"Function not found."},
        {method:"status",args:[],validator:"status"}
    ]
    QtObject {
        id: shellMock
        property var shellConfig: ({bar:{layout:{left:[{id:"io.github.bolens.multi-monitor-workspaces",count:3,_multiMonitorWorkspacesRevision:0}]}}})
        function updateEntryInline(_id, _entry) { throw new Error("read-only IPC case attempted persistence") }
    }
    QtObject {
        id: widgetMock
        property var actions: []
        property bool opened: false
        function actionFor(id, action) { actions = actions.concat([{id:id,action:action}]); return true }
        function showSettings(_page) { throw new Error("read-only IPC case attempted UI control") }
        function closeSettings() { opened = false }
        function settingsStatus() { return {open:opened} }
        function scrollSettings(_position) { throw new Error("read-only IPC case attempted UI control") }
    }
    Service { id: service; shell: shellMock }
    property bool registered: false
    function fixtureReady() {
        if (!root.registered) {
            service.registerWidget("DP-1", widgetMock)
            root.registered = true
        }
        return service.monitorNames().join(",") === "DP-1" && service.effectiveSettings.count === 3
    }
    function validateValue(kind, response) {
        root.assertThat(kind === "status", "unknown validator")
        const status = JSON.parse(response)
        root.assertThat(status.ipcVersion === 1 && status.settings.count === 3
            && status.monitors.join(",") === "DP-1" && status.pending === false, "status projection")
    }
    function finalState() {
        root.assertThat(JSON.stringify(widgetMock.actions) === '[{"id":2,"action":"focus"}]', "typed parser errors invoked an action")
        root.assertThat(!widgetMock.opened && service.pendingPatch === null, "unexpected UI or persistence")
    }

    function assertThat(ok, message) {
        if (!ok) throw new Error("IPC transport contract: " + message)
    }
    function announceReady() {
        if (root.announced || !root.fixtureReady()) return
        root.announced = true
        console.log("QML_CI_BOOTSTRAP_READY")
    }
    function startBootstrap() {
        if (!root.announced) return "not ready"
        if (root.started) return "already started"
        root.started = true
        Qt.callLater(root.next)
        return "started"
    }
    function next() {
        if (root.step === root.calls.length) {
            root.finalState()
            root.finished = true
            console.log("MMW_QML_IPC_TRANSPORT_OK")
            Qt.quit()
            return
        }
        const call = root.calls[root.step]
        const prefix = [root.executable, "ipc", "--no-color", "--pid", String(Quickshell.processId)]
        ipc.command = call.show === true ? prefix.concat(["show"])
            : prefix.concat(["call", root.targetName, call.method]).concat(call.args)
        ipc.running = true
    }
    function acceptResponse(call, code, stdoutText, stderrText) {
        root.assertThat(stdoutText.length <= 65536 && stderrText.length <= 65536, "oversized child output")
        const observation = JSON.stringify({step:root.step,method:call.show === true ? "show" : call.method,
            code:code,stdout:stdoutText,stderr:stderrText})
        console.log("IPC_TRANSPORT_REPLY_JSON " + observation)
        root.assertThat(stderrText === "", "unexpected child stderr: " + observation)
        root.assertThat(code === (call.code === undefined ? 0 : call.code), "wrong child exit status: " + observation)
        if (call.show === true) {
            const targets = stdoutText.split("\n").filter(function(line) { return line.indexOf("target ") === 0 }).sort()
            root.assertThat(JSON.stringify(targets) === JSON.stringify(["target qml-ci-bootstrap", "target " + root.targetName].sort()), "wrong instance handler census")
            root.assertThat(stdoutText.indexOf(root.requiredSignature) >= 0, "missing real typed signature")
        } else if (call.validator) root.validateValue(call.validator, stdoutText)
        else root.assertThat(stdoutText === call.expected, "wrong response for " + call.method)
    }
    IpcHandler {
        target: "qml-ci-bootstrap"
        function start(): string { return root.startBootstrap() }
    }
    Process {
        id: ipc
        stdout: StdioCollector { id: ipcOutput; waitForEnd: true }
        stderr: StdioCollector { id: ipcErrors; waitForEnd: true }
        onExited: function(code) {
            root.acceptResponse(root.calls[root.step], code, String(ipcOutput.text || "").trim(), String(ipcErrors.text || "").trim())
            root.step += 1
            Qt.callLater(root.next)
        }
    }
    Component.onCompleted: Qt.callLater(root.announceReady)
    Timer {
        interval: 8000
        running: !root.finished
        repeat: false
        onTriggered: { throw new Error("IPC transport fixture deadline at step " + root.step) }
    }
}
