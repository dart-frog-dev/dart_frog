/**
 * @file Provides utilities for inspecting and dealing with a Dart Frog
 * project's.
 */

const fs = require("fs");
const path = require("node:path");
import {
  QuickInputButton,
  QuickPickItem,
  QuickPickItemKind,
  QuickPickOptions,
  window,
  workspace,
} from "vscode";

/**
 * Normalizes a file path to Dart Frog route path from the root of the
 * Dart Frog project.
 *
 * @param {string} selectedPath User-selected path to a file, including
 * directories,
 * @param {string} dartFrogProjectPath The path to the root of the Dart Frog
 * project.
 * @returns {string} The Dart Frog route path. If the {@link selectedPath} is
 * not within the Dart Frog project routes, it returns "/".
 *
 * @see {@link nearestParentDartFrogProject}, to find the root of a Dart Frog
 * project from a file path.
 */
export function normalizeRoutePath(
  selectedPath: string,
  dartFrogProjectPath: string,
): string {
  const routesPath = path.join(dartFrogProjectPath, "routes");
  if (!selectedPath.startsWith(routesPath)) {
    return "/";
  }

  const relativePath = path.relative(routesPath, selectedPath);
  const parsedRelativePath = path.parse(relativePath);

  let routePath;
  const isFile = parsedRelativePath.ext !== "";
  if (!isFile) {
    routePath = relativePath;
  } else if (
    parsedRelativePath.name === "index" ||
    parsedRelativePath.name === "_middleware"
  ) {
    routePath = parsedRelativePath.dir;
  } else {
    routePath = path.join(parsedRelativePath.dir, parsedRelativePath.name);
  }

  if (routePath === "") {
    return "/";
  } else {
    return routePath.replace(path.sep, "/");
  }
}

/**
 * Finds the root of a Dart Frog project from a file path by traversing up the
 * directory tree.
 *
 * @param filePath The path to a file, including directories, to check.
 * @returns {string | undefined} The path to the root of the Dart Frog project,
 * or `undefined` if there is no Dart Frog project in the {@link filePath}.
 * @see {@link isDartFrogProject}, to determine if a file is a Dart Frog
 * project.
 */
export function nearestParentDartFrogProject(
  filePath: string,
): string | undefined {
  if (!path.isAbsolute(filePath)) {
    console.trace(
      `nearestParentDartFrogProject called with a relative path: "${filePath}"`,
    );
    return undefined;
  }

  let currentPath = filePath;
  while (true) {
    if (isDartFrogProject(currentPath)) return currentPath;
    const parentPath = path.dirname(currentPath);
    if (parentPath === currentPath) return undefined;
    currentPath = parentPath;
  }
}

/**
 * Finds all Dart Frog projects that are children of a directory.
 *
 * Nested Dart Frog projects are not considered. Therefore, if the
 * {@link filePath} is a Dart Frog project, then only that project is reported.
 * The same logic applies to subdirectories. If a subdirectory is also a Dart
 * Frog project, then all of its subdirectories are ignored and only the
 * shallowest Dart Frog project is reported.
 *
 * @param filePath The path to the directory to check for.
 * @returns {Array<string> | undefined} A set of paths to Dart Frog projects
 * that are children of the {@link filePath}, or `undefined` if there are no
 * Dart Frog projects in the {@link filePath}.
 */
export function nearestChildDartFrogProjects(
  filePath: string,
): Array<string> | undefined {
  if (!fs.existsSync(filePath) || !fs.statSync(filePath).isDirectory()) {
    return undefined;
  }

  if (isDartFrogProject(filePath)) {
    return [filePath];
  }

  const dartFrogProjects = new Set<string>();

  let currentSubdirectories = fs
    .readdirSync(filePath)
    .map((file: string) => path.join(filePath, file))
    .filter((file: string) => fs.statSync(file).isDirectory());

  while (currentSubdirectories.length > 0) {
    for (let i = 0; i < currentSubdirectories.length; i++) {
      const subdirectory = currentSubdirectories[i];
      if (isDartFrogProject(subdirectory)) {
        dartFrogProjects.add(subdirectory);
        currentSubdirectories.splice(i, 1);
        i--;
      }
    }

    const nextSubdirectories: string[] = [];
    for (const subdirectory of currentSubdirectories) {
      const subdirectorySubdirectories = fs
        .readdirSync(subdirectory)
        .map((file: string) => path.join(subdirectory, file))
        .filter((file: string) => fs.statSync(file).isDirectory());
      nextSubdirectories.push(...subdirectorySubdirectories);
    }
    currentSubdirectories = nextSubdirectories;
  }

  if (dartFrogProjects.size === 0) {
    return undefined;
  }

  return Array.from(dartFrogProjects);
}

/**
 * Determines if a {@link filePath} is a Dart Frog project.
 *
 * A file is in a Dart Frog project if it is in a directory that contains a
 * `routes` directory and, at the same level, a `pubspec.yaml` file with a
 * `dart_frog` dependency.
 *
 * To avoid parsing the `pubspec.yaml` file, we use a heuristic where we simply
 * check if the `dart_frog` string is in the `pubspec.yaml` file.
 *
 * @param {string} filePath The path to a file, including directories, to check.
 * @returns {boolean} Whether or not the {@link filePath} is the root of Dart
 * Frog project.
 */
export function isDartFrogProject(filePath: string): boolean {
  const routesPath = path.join(filePath, "routes");
  const pubspecPath = path.join(filePath, "pubspec.yaml");

  if (fs.existsSync(routesPath) && fs.existsSync(pubspecPath)) {
    const pubspec = fs.readFileSync(pubspecPath, "utf-8");
    return pubspec.includes("dart_frog:");
  }

  return false;
}

/**
 * Determines if the user's workspace contains a Dart Frog project.
 *
 * @returns {boolean} Whether or not the user's workspace contains a Dart Frog
 * project.
 */
export function canResolveDartFrogProjectPath(): boolean {
  return (
    resolveDartFrogProjectPathFromWorkspaceFolders() !== undefined ||
    resolveDartFrogProjectPathFromActiveTextEditor() !== undefined
  );
}

/**
 * Resolves a path of a file or directory within a Dart Frog project from the
 * user's workspace.
 *
 * Usually used for when the command is launched from the command palette since
 * it lacks a defined path.
 *
 * @param {function} _nearestParentDartFrogProject A function, used for testing,
 * that finds the root of a Dart Frog project from a file path by traversing up
 * the directory tree. Defaults to {@link nearestParentDartFrogProject}.
 * @returns {string | undefined} A path, derived from the user's workspace
 * folders, that is located within a Dart Frog project; or `undefined` if no
 * such path could be resolved.
 */
export function resolveDartFrogProjectPathFromWorkspaceFolders(
  _nearestParentDartFrogProject: (
    filePath: string,
  ) => string | undefined = nearestParentDartFrogProject,
): Array<string> | undefined {
  if (workspace.workspaceFolders && workspace.workspaceFolders.length > 0) {
    const currentWorkspaceFolder = path.normalize(
      workspace.workspaceFolders[0].uri.fsPath,
    );
    if (_nearestParentDartFrogProject(currentWorkspaceFolder)) {
      return [currentWorkspaceFolder];
    }

    return nearestChildDartFrogProjects(currentWorkspaceFolder);
  }

  return undefined;
}

/**
 * Resolves a path of a file or directory within a Dart Frog project from the
 * user's active text editor.
 *
 * Usually used for when the command is launched from the command palette since
 * it lacks a defined path.
 *
 * @param _nearestParentDartFrogProject A function, used for testing, that
 * finds the root of a Dart Frog project from a file path by traversing up the
 * directory tree. Defaults to {@link nearestParentDartFrogProject}.
 * @returns {string | undefined} A path, derived from the user's active text
 * editor, that is located within a Dart Frog project; or `undefined` if no such
 * path could be resolved.
 */
export function resolveDartFrogProjectPathFromActiveTextEditor(
  _nearestParentDartFrogProject: (
    filePath: string,
  ) => string | undefined = nearestParentDartFrogProject,
): string | undefined {
  if (window.activeTextEditor) {
    const currentTextEditorPath = path.normalize(
      window.activeTextEditor.document.uri.fsPath,
    );
    const dartFrogProjectPath = _nearestParentDartFrogProject(
      currentTextEditorPath,
    );

    if (dartFrogProjectPath) {
      const routesPath = path.join(dartFrogProjectPath, "routes");
      if (
        currentTextEditorPath.startsWith(routesPath) &&
        currentTextEditorPath.endsWith(".dart")
      ) {
        return currentTextEditorPath;
      }
    }
  }

  return undefined;
}

/**
 * Prompts the user to select a Dart Frog project from a list of resolved Dart
 * Frog projects.
 *
 * If there is only one Dart Frog project, since there is no possible selection,
 * the user is not prompted and the project is immediately returned.
 *
 * @param options The options for the {@link QuickPick}.
 * @param projectPaths The resolved project paths.
 * @returns The selected project path or `undefined` if the user cancelled the
 * selection.
 */
export async function quickPickProject(
  options: QuickPickOptions,
  projectPaths: string[],
) {
  if (projectPaths.length === 0) {
    return;
  }
  if (projectPaths.length === 1) {
    return projectPaths[0];
  }

  const quickPick = window.createQuickPick<PickableDartFrogProject>();
  quickPick.placeholder = options.placeHolder ?? "Select a Dart Frog project";
  quickPick.busy = false;
  quickPick.ignoreFocusOut = options.ignoreFocusOut ?? true;
  quickPick.canSelectMany = options.canPickMany ?? false;
  quickPick.items = projectPaths.map(
    (projectPath) => new PickableDartFrogProject(projectPath),
  );
  quickPick.show();

  return new Promise<string | undefined>((resolve) => {
    quickPick.onDidChangeSelection((value) => {
      quickPick.dispose();

      const selection =
        !value || value.length === 0 ? undefined : value[0]!.projectPath;
      if (selection) {
        options.onDidSelectItem?.(value[0]);
      }

      resolve(selection);
    });
  });
}

/**
 * A {@link QuickPickItem} that represents a Dart Frog project.
 *
 * @see {@link quickPickApplication}
 */
class PickableDartFrogProject implements QuickPickItem {
  constructor(dartFrogProjectPath: string) {
    this.label = `$(dart-frog) ${path.basename(dartFrogProjectPath)}`;
    this.description = dartFrogProjectPath;
    this.projectPath = dartFrogProjectPath;
  }

  public readonly projectPath: string;

  label: string;
  kind?: QuickPickItemKind | undefined;
  description?: string | undefined;
  detail?: string | undefined;
  picked?: boolean | undefined;
  alwaysShow?: boolean | undefined;
  buttons?: readonly QuickInputButton[] | undefined;
}
