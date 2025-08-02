const cp = require("child_process");

import {
  InputBoxOptions,
  OpenDialogOptions,
  ProgressOptions,
  Uri,
  window,
} from "vscode";
import {
  isDartFrogCLIInstalled,
  nearestParentDartFrogProject,
  normalizeRoutePath,
  quickPickProject,
  resolveDartFrogProjectPathFromActiveTextEditor,
  resolveDartFrogProjectPathFromWorkspaceFolders,
  suggestInstallingDartFrogCLI,
} from "../utils";

/**
 * Command to create a new route.
 *
 * This command is available from the command palette and the context menu.
 *
 * When launching the command from the command palette, the Uri is undefined.
 * Therefore, the command attempts to resolve a path from the user's active text
 * editor first and then from the user's workspace folders. If no path can be
 * resolved from either of those sources, the user is prompted to select a valid
 * directory or file to create the route in.
 *
 * When launching the command from the context menu, the Uri corresponds to the
 * selected file or directory. Only those directories or dart files under a
 * `routes` directory show the command in the context menu. Therefore the user
 * does not need to select a directory or file via the open dialog.
 *
 * All the logic associated with creating a new route is handled by the
 * `dart_frog new route` command, from the Dart Frog CLI.
 *
 * @see [Dart Frog CLI `new` command implementation](https://github.com/dart-frog-dev/dart_frog/tree/main/packages/dart_frog_cli/lib/src/commands/new)
 * @param {Uri | undefined} uri
 */
export const newRoute = async (uri: Uri | undefined): Promise<void> => {
  if (!isDartFrogCLIInstalled()) {
    await suggestInstallingDartFrogCLI(
      "Running this command requires Dart Frog CLI to be installed."
    );
  }

  let selectedPath;
  if (uri === undefined) {
    selectedPath = resolveDartFrogProjectPathFromActiveTextEditor();

    if (!selectedPath) {
      const dartFrogProjectsPaths =
        resolveDartFrogProjectPathFromWorkspaceFolders();

      if (dartFrogProjectsPaths && dartFrogProjectsPaths.length > 0) {
        const selection = await quickPickProject({}, dartFrogProjectsPaths);
        if (!selection) {
          return;
        }
        selectedPath = selection;
      }
    }
    if (!selectedPath) {
      selectedPath = await promptForTargetDirectory();
    }
    if (!selectedPath) {
      window.showErrorMessage("Please select a valid directory");
      return;
    }
  } else {
    selectedPath = uri.fsPath;
  }

  const dartFrogProjectPath = nearestParentDartFrogProject(selectedPath);
  if (!dartFrogProjectPath) {
    window.showErrorMessage(
      "No Dart Frog project found in the selected directory"
    );
    return;
  }

  const normalizedRoutePath = normalizeRoutePath(
    selectedPath,
    dartFrogProjectPath
  );

  const separator = normalizedRoutePath.endsWith("/") ? "" : "/";
  const routePath = await promptRouteName(`${normalizedRoutePath}${separator}`);
  if (routePath === undefined || routePath.trim() === "") {
    window.showErrorMessage("Please enter a valid route path");
    return;
  }

  const options: ProgressOptions = {
    location: 15,
    title: `Creating '${routePath}' route...`,
  };
  window.withProgress(options, async function () {
    executeDartFrogNewRouteCommand(routePath, dartFrogProjectPath);
  });
};

/**
 * Shows an input box to the user and returns a Thenable that resolves to
 * a string the user provided.
 *
 * @returns The route name the user provided or undefined if the user canceled.
 */
function promptRouteName(routePath: string): Thenable<string | undefined> {
  const inputBoxOptions: InputBoxOptions = {
    prompt: "Route path",
    value: routePath,
    placeHolder: "index",
  };
  return window.showInputBox(inputBoxOptions);
}

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
    openLabel: "Select a folder or file to create the route in",
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
 * Runs the `dart_frog new route` command with the given route path.
 *
 * @param {string} routePath, the path of the new route.
 * @param {string} dartFrogProjectPath, the root of the Dart Frog project.
 */
function executeDartFrogNewRouteCommand(
  routePath: string,
  dartFrogProjectPath: string
): void {
  cp.exec(
    `dart_frog new route "${routePath}"`,
    {
      cwd: dartFrogProjectPath,
    },
    function (error: Error) {
      if (error) {
        window.showErrorMessage(error.message);
      }
    }
  );
}
