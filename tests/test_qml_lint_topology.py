"""Driver staging/cleanup only; fake executables never claim Qt acceptance."""
import json
import os
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TARGETS = ['Button.qml', 'WidgetButton.qml', 'BarHostAccess.qml', 'BarWidget.qml',
           'SettingsPanel.qml', 'Service.qml', 'RuntimePaletteContractTest.qml', 'RuntimeIpcTransportTest.qml']


class FlatLintTopology(unittest.TestCase):
    def run_driver(self, status):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            checkout = root / 'checkout'; (checkout / 'scripts').mkdir(parents=True)
            (checkout / 'tests/qml').mkdir(parents=True)
            shutil.copy2(ROOT / 'scripts/lint-qml', checkout / 'scripts/lint-qml')
            for name in TARGETS:
                parent = checkout / 'tests/qml' if name.startswith('Runtime') else checkout
                (parent / name).write_text('import QtQuick\nItem {}\n')
            (checkout / 'qmldir').write_text('Service 1.0 Service.qml\n')
            (checkout / '.qmllint.ini').write_text('[General]\nMaxWarnings=0\n')
            (checkout / '.git').write_text('unrelated private metadata')
            shell = root / 'shell'
            for name in ('Commons', 'Ui'):
                (shell / name).mkdir(parents=True)
                (shell / name / 'qmldir').write_text('module qs.' + name + '\n')
            controls = root / 'controls.json'
            (checkout / 'scripts/check-qml-lint-controls.py').write_text(
                'import os,json,sys\nfrom pathlib import Path\n'
                'Path(os.environ["TEST_CONTROLS"]).write_text(json.dumps(sys.argv[1:]))\n')
            record = root / 'command.json'
            fake = root / 'qmllint'
            fake.write_text('#!' + sys.executable + '\nimport os,json,sys\nfrom pathlib import Path\n'
                            'Path(os.environ["TEST_RECORD"]).write_text(json.dumps({"cwd":os.getcwd(),"args":sys.argv[1:],"files":sorted(p.name for p in Path.cwd().iterdir())}))\n'
                            'sys.exit(int(os.environ["TEST_STATUS"]))\n')
            fake.chmod(0o700)
            result = subprocess.run(['bash', str(checkout / 'scripts/lint-qml')], text=True, capture_output=True,
                                    timeout=5, env={**os.environ, 'QMLLINT': str(fake), 'OMARCHY_SHELL_ROOT': str(shell),
                                                   'QML_TOOLING_IMPORT_ROOT': str(root / 'metadata'), 'TEST_RECORD': str(record),
                                                   'TEST_CONTROLS': str(controls), 'TEST_STATUS': str(status)})
            observed = json.loads(record.read_text())
            self.assertNotEqual(Path(observed['cwd']), checkout)
            self.assertFalse(Path(observed['cwd']).exists(), 'owned staging must be removed on success and failure')
            self.assertEqual([arg for arg in observed['args'] if arg.endswith('.qml')], TARGETS)
            self.assertTrue(set(TARGETS) <= set(observed['files']))
            self.assertIn('qmldir', observed['files'])
            self.assertIn('.qmllint.ini', observed['files'])
            self.assertNotIn('.git', observed['files'])
            self.assertEqual((checkout / '.git').read_text(), 'unrelated private metadata')
            self.assertEqual(observed['args'][0], '--bare')
            if status == 0:
                self.assertTrue(controls.exists(), 'real control entrypoint remains mandatory after source lint')
                self.assertIn('--policy', json.loads(controls.read_text()))
            else:
                self.assertFalse(controls.exists(), 'a failed source gate must not be hidden by later checks')
            return result

    def test_flat_local_types_and_canonical_new_harnesses(self):
        self.assertEqual(self.run_driver(0).returncode, 0)

    def test_source_failure_propagates_and_cleans_owned_staging(self):
        self.assertEqual(self.run_driver(7).returncode, 7)


if __name__ == '__main__':
    unittest.main()
