/**
 * This file downloads, unzipps, and launches VSCode with extension test
 * parameters.
 *
 * @see https://code.visualstudio.com/api/working-with-extensions/testing-extension#the-test-script
 * @see https://code.visualstudio.com/api/working-with-extensions/testing-extension#custom-setup-with-vscodetestelectron
 * @see https://github.com/prettier/prettier-vscode/blob/main/src/test/runTests.ts
 */

import * as cp from "child_process";
import * as path from "path";
import {
  downloadAndUnzipVSCode,
  resolveCliArgsFromVSCodeExecutablePath,
  runTests,
} from "@vscode/test-electron";

async function main() {
  try {
    const extensionDevelopmentPath = path.resolve(__dirname, "../../");
    const extensionTestsPath = path.resolve(__dirname, "./suite/index");
    const vscodeExecutablePath = await downloadAndUnzipVSCode();
    const [cliPath, ...args] =
      resolveCliArgsFromVSCodeExecutablePath(vscodeExecutablePath);

    // Install Dart Code extension
    cp.spawnSync(
      cliPath,
      [...args, "--install-extension", "Dart-Code.dart-code"],
      {
        encoding: "utf-8",
        stdio: "inherit",
      }
    );

    // Download VSCode, unzip it and run the integration test
    await runTests({
      vscodeExecutablePath,
      extensionDevelopmentPath,
      extensionTestsPath,
    });
  } catch (err) {
    console.error("❌ Failed to run tests");
    console.error(err);
    process.exit(1);
  }
}

main();
