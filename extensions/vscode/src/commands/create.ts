const cp = require("child_process");
const path = require("node:path");

import {
  InputBoxOptions,
  OpenDialogOptions,
  ProgressOptions,
  Uri,
  window,
} from "vscode";
import { isDartFrogCLIInstalled, suggestInstallingDartFrogCLI } from "../utils";

/**
 * Creates a new Dart Frog project.
 *
 * This command is available from the command palette and the context menu.
 *
 * When launching the command from the command palette, the Uri is undefined
 * and the user is prompted to select a valid directory or file to create the
 * project in.
 *
 * When launching the command from the context menu, the Uri corresponds to the
 * selected file or directory. Only those directories that are not Dart Frog
 * projects already show the command in the context menu.
 *
 * The user will always be prompted for a project name, which is pre-filled with
 * the name of the directory the project will be created in. Mimicking the
 * Dart Frog CLI create command implementation.
 *
 * All the logic associated with creating a new project is handled by the
 * `dart_frog create` command, from the Dart Frog CLI.
 *
 * @param {Uri | undefined} uri
 * @see {@link https://github.com/dart-frog-dev/dart_frog/blob/main/packages/dart_frog_cli/lib/src/commands/create/create.dart Dart Frog CLI `create` command implementation.}
 */
export const create = async (uri: Uri | undefined): Promise<void> => {
  if (!isDartFrogCLIInstalled()) {
    await suggestInstallingDartFrogCLI(
      "Running this command requires Dart Frog CLI to be installed."
    );
  }

  let outputDirectory =
    uri === undefined ? await promptForTargetDirectory() : uri.fsPath;

  if (outputDirectory === undefined) {
    return;
  }

  let projectName = path.basename(path.normalize(outputDirectory));
  projectName = await promptProjectName(projectName);

  if (projectName === undefined || projectName.trim() === "") {
    window.showErrorMessage("Please enter a project name");
    return;
  }

  const options: ProgressOptions = {
    location: 15,
    title: `Creating ${projectName} Dart Frog Project...`,
  };
  window.withProgress(options, async function () {
    executeDartFrogCreateCommand(outputDirectory!, projectName);
  });
};

/**
 * Shows an open dialog to the user and returns a Promise that resolves
 * to a string when the user selects a folder or file.
 *
 * This is used when the user activates the command from the command palette
 * instead of the context menu.
 *
 * @returns The path to the selected folder or file or undefined if the user
 * canceled.
 */
async function promptForTargetDirectory(): Promise<string | undefined> {
  const options: OpenDialogOptions = {
    canSelectMany: false,
    openLabel: "Select a folder or file to create the project in",
    canSelectFolders: true,
    canSelectFiles: true,
  };
  return window.showOpenDialog(options).then((uri) => {
    if (Array.isArray(uri) && uri.length > 0) {
      return uri[0].fsPath;
    }

    return undefined;
  });
}

/**
 * Shows an input box to the user and returns a Thenable that resolves to
 * a string the user provided.
 *
 * @param {string} value The default value to show in the input box.
 * @returns The route name the user provided or undefined if the user canceled.
 */
function promptProjectName(value: string): Thenable<string | undefined> {
  const inputBoxOptions: InputBoxOptions = {
    prompt: "Project name",
    value: value,
  };
  return window.showInputBox(inputBoxOptions);
}

async function executeDartFrogCreateCommand(
  outputDirectory: string,
  projectName: string
): Promise<void> {
  return cp.exec(
    `dart_frog create "${projectName}"`,
    {
      cwd: outputDirectory,
    },
    function (error: Error) {
      if (error) {
        window.showErrorMessage(error.message);
      }
    }
  );
}
