import * as vscode from "vscode";
const cp = require("child_process");
const semver = require("semver");

/**
 * The semantic version constraints for Dart Frog CLI to be compatible with this
 * extension.
 */
const compatibleCLIVersion = ">=1.1.1 <2.0.0";

/**
 * Collects the version of Dart Frog CLI installed in the user's system.
 *
 * @returns {string | undefined} The semantic version of Dart Frog CLI installed
 * in the user's system, or null if Dart Frog CLI is not installed.
 */
export function readDartFrogCLIVersion(): string | undefined {
  try {
    const result = cp.execSync(`dart_frog --version`);
    const decodedResult = new TextDecoder().decode(result);
    return decodedResult.split("\n", 1).at(0);
  } catch (error) {
    console.error(error);
    return undefined;
  }
}

/**
 * Collects the latest available version of Dart Frog CLI.
 *
 * @returns {string | undefined} The latest available semantic version of
 * Dart Frog CLI, or undefined if Dart Frog CLI is not installed.
 */
export function readLatestDartFrogCLIVersion(): string | undefined {
  try {
    const result = cp.execSync(`dart_frog --version`);
    const decodedResult = new TextDecoder().decode(result);
    const lines = decodedResult.split("\n");
    if (lines.length <= 2) {
      return lines.at(0);
    }
    return lines.at(2)?.split(" ").at(-1);
  } catch (error) {
    console.error(error);
    return undefined;
  }
}

/**
 * Checks if the version of Dart Frog CLI installed in the user's system is
 * compatible with this extension.
 *
 * @param {string} version The semantic version of Dart Frog CLI installed in
 * the user's system.
 * @returns {Boolean} True if the version of Dart Frog CLI installed in the
 * user's system is compatible with this extension, false otherwise.
 * @see {@link readDartFrogCLIVersion}, to collect the version of Dart Frog CLI.
 */
export function isCompatibleDartFrogCLIVersion(version: string): Boolean {
  return semver.satisfies(version, compatibleCLIVersion);
}

/**
 * Whether the user has Dart Frog CLI installed in their system.
 *
 * @returns {boolean} True if the user has Dart Frog CLI installed in their
 * system, false otherwise.
 */
export function isDartFrogCLIInstalled(): boolean {
  return readDartFrogCLIVersion() !== undefined;
}

/**
 * Opens the changelog for the specified version in a browser.
 *
 * @param {string} version The semantic version of Dart Frog CLI which changelog
 * is requested to open.
 */
export async function openChangelog(version: string): Promise<void> {
  vscode.commands.executeCommand(
    "vscode.open",
    vscode.Uri.parse(
      `https://github.com/dart-frog-dev/dart_frog/releases/tag/dart_frog_cli-v${version}`
    )
  );
}
