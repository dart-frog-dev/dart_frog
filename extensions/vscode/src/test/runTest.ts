/**
 * This file downloads, unzipps, and launches VSCode with extension test
 * parameters.
 *
 * @see https://code.visualstudio.com/api/working-with-extensions/testing-extension#the-test-script
 * @see https://code.visualstudio.com/api/working-with-extensions/testing-extension#custom-setup-with-vscodetestelectron
 * @see https://github.com/prettier/prettier-vscode/blob/main/src/test/runTests.ts
 */

import * as cp from "child_process";
import * as fs from "fs";
import * as os from "os";
import * as path from "path";
import {
  downloadAndUnzipVSCode,
  resolveCliArgsFromVSCodeExecutablePath,
  runTests,
} from "@vscode/test-electron";

const VSCODE_VERSION = "1.146.0";

async function main() {
  try {
    const extensionDevelopmentPath = path.resolve(__dirname, "../../");
    const extensionTestsPath = path.resolve(__dirname, "./suite/index");
    const root = fs.mkdtempSync(
      path.join(os.tmpdir(), "dart-frog-vscode-test-"),
    );
    const userDataDir = path.join(root, "user-data");
    const extensionsDir = path.join(root, "extensions");

    fs.mkdirSync(path.join(userDataDir, "User"), { recursive: true });
    fs.writeFileSync(
      path.join(userDataDir, "User", "settings.json"),
      JSON.stringify(
        {
          "chat.disableAIFeatures": true,
          "github.copilot.enable": { "*": false },
          "extensions.autoUpdate": false,
          "extensions.autoCheckUpdates": false,
          "telemetry.telemetryLevel": "off",
          "update.mode": "none",
          "workbench.startupEditor": "none",
          "security.workspace.trust.enabled": false,
        },
        null,
        2,
      ),
    );

    const vscodeExecutablePath = await downloadAndUnzipVSCode(VSCODE_VERSION);
    const [cliPath] =
      resolveCliArgsFromVSCodeExecutablePath(vscodeExecutablePath);

    cp.spawnSync(
      cliPath,
      [
        `--user-data-dir=${userDataDir}`,
        `--extensions-dir=${extensionsDir}`,
        "--install-extension",
        "Dart-Code.dart-code",
      ],
      { encoding: "utf-8", stdio: "inherit" },
    );

    await runTests({
      vscodeExecutablePath,
      extensionDevelopmentPath,
      extensionTestsPath,
      launchArgs: [
        `--user-data-dir=${userDataDir}`,
        `--extensions-dir=${extensionsDir}`,
        "--disable-workspace-trust",
        "--skip-welcome",
        "--skip-release-notes",
        "--disable-gpu",
      ],
    });
  } catch (err) {
    console.error("❌ Failed to run tests");
    console.error(err);
    process.exit(1);
  }
}

main();
