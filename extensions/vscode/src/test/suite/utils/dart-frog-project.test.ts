const sinon = require("sinon");
var proxyquire = require("proxyquire");
const path = require("node:path");

import * as assert from "assert";
import { afterEach, beforeEach } from "mocha";

suite("normalizeRoutePath", () => {
  let fsStub: any;
  let normalizeRoutePath: any;

  beforeEach(() => {
    fsStub = {
      existsSync: sinon.stub(),
      readFileSync: sinon.stub(),
    };

    normalizeRoutePath = proxyquire("../../../utils/dart-frog-project", {
      fs: fsStub,
    }).normalizeRoutePath;
  });

  afterEach(() => {
    sinon.restore();
  });

  test("returns the route path", () => {
    const dartFrogPath = "/home/user";
    const routesPath = path.join(dartFrogPath, "routes");
    const pubspecPath = path.join(dartFrogPath, "pubspec.yaml");

    fsStub.existsSync.withArgs(routesPath).returns(true);
    fsStub.existsSync.withArgs(pubspecPath).returns(true);
    fsStub.readFileSync
      .withArgs(pubspecPath, "utf-8")
      .returns(validPubspecYaml);

    assert.equal(
      normalizeRoutePath(`${dartFrogPath}/routes`, dartFrogPath),
      "/",
    );
    assert.equal(
      normalizeRoutePath(`${dartFrogPath}/routes/index.dart`, dartFrogPath),
      "/",
    );
    assert.equal(
      normalizeRoutePath(`${dartFrogPath}/routes/z.py`, dartFrogPath),
      "z",
    );
    assert.equal(
      normalizeRoutePath(`${dartFrogPath}/routes/tennis.dart`, dartFrogPath),
      "tennis",
    );
    assert.equal(
      normalizeRoutePath(
        `${dartFrogPath}/routes/sports/tennis.dart`,
        dartFrogPath,
      ),
      "sports/tennis",
    );
    assert.equal(
      normalizeRoutePath(
        `${dartFrogPath}/routes/sports/tennis/players/[id]/spanish/nadal.dart`,
        dartFrogPath,
      ),
      "sports/tennis/players/[id]/spanish/nadal",
    );
    assert.equal(
      normalizeRoutePath(
        `${dartFrogPath}/routes/a/routes/b/index.dart`,
        dartFrogPath,
      ),
      "a/routes/b",
    );
    assert.equal(
      normalizeRoutePath(`${dartFrogPath}/routes/a/b/`, dartFrogPath),
      "a/b",
    );
    assert.equal(
      normalizeRoutePath(`${dartFrogPath}/routes/a/routes/b/`, dartFrogPath),
      "a/routes/b",
    );
    assert.equal(
      normalizeRoutePath(`${dartFrogPath}/routes/a/[id]/b/`, dartFrogPath),
      "a/[id]/b",
    );
    assert.equal(
      normalizeRoutePath(`${dartFrogPath}/tennis.dart`, dartFrogPath),
      "/",
    );
    assert.equal(
      normalizeRoutePath(
        `${dartFrogPath}/routes/a/b/_middleware.dart`,
        dartFrogPath,
      ),
      "a/b",
    );
  });
});

suite("nearestParentDartFrogProject", () => {
  let fsStub: any;
  let nearestParentDartFrogProject: any;

  beforeEach(() => {
    fsStub = {
      existsSync: sinon.stub(),
      readFileSync: sinon.stub(),
    };

    nearestParentDartFrogProject = proxyquire(
      "../../../utils/dart-frog-project",
      {
        fs: fsStub,
      },
    ).nearestParentDartFrogProject;
  });

  afterEach(() => {
    sinon.restore();
  });

  test("returns the path to the root of the Dart Frog project", () => {
    const dartFrogPath = "/home/user";
    const routesPath = path.join(dartFrogPath, "routes");
    const pubspecPath = path.join(dartFrogPath, "pubspec.yaml");

    fsStub.existsSync.withArgs(routesPath).returns(true);
    fsStub.existsSync.withArgs(pubspecPath).returns(true);
    fsStub.readFileSync
      .withArgs(pubspecPath, "utf-8")
      .returns(validPubspecYaml);

    assert.equal(
      nearestParentDartFrogProject(
        `${dartFrogPath}/routes/a/routes/b/index.dart`,
      ),
      dartFrogPath,
    );
    assert.equal(
      nearestParentDartFrogProject(`${dartFrogPath}/routes/index.dart`),
      dartFrogPath,
    );
    assert.equal(
      nearestParentDartFrogProject(`${dartFrogPath}/routes/z.py`),
      dartFrogPath,
    );
    assert.equal(
      nearestParentDartFrogProject(`${dartFrogPath}/tennis.dart`),
      dartFrogPath,
    );
  });

  test("returns the path to the root of the Dart Frog project when nested", () => {
    const dartFrogPath1 = "/home/user";
    const routesPath1 = path.join(dartFrogPath1, "routes");
    const pubspecPath1 = path.join(dartFrogPath1, "pubspec.yaml");

    const dartFrogPath2 = "/home/user/Developer/myserver";
    const routesPath2 = path.join(dartFrogPath2, "routes");
    const pubspecPath2 = path.join(dartFrogPath2, "pubspec.yaml");

    fsStub.existsSync.withArgs(routesPath1).returns(true);
    fsStub.existsSync.withArgs(pubspecPath1).returns(true);
    fsStub.readFileSync
      .withArgs(pubspecPath1, "utf-8")
      .returns(validPubspecYaml);

    fsStub.existsSync.withArgs(routesPath2).returns(true);
    fsStub.existsSync.withArgs(pubspecPath2).returns(true);
    fsStub.readFileSync
      .withArgs(pubspecPath2, "utf-8")
      .returns(validPubspecYaml);

    assert.equal(
      nearestParentDartFrogProject(
        `${dartFrogPath2}/routes/a/routes/b/index.dart`,
      ),
      dartFrogPath2,
    );
    assert.equal(
      nearestParentDartFrogProject(`${dartFrogPath1}/routes/index.dart`),
      dartFrogPath1,
    );
  });

  test("returns undefined when there is no Dart Frog project", () => {
    const dartFrogPath = "/home/user";
    const routesPath = path.join(dartFrogPath, "routes");
    const pubspecPath = path.join(dartFrogPath, "pubspec.yaml");

    fsStub.existsSync.withArgs(routesPath).returns(false);
    fsStub.existsSync.withArgs(pubspecPath).returns(false);
    fsStub.readFileSync
      .withArgs(pubspecPath, "utf-8")
      .returns(invalidPubspecYaml);

    const result = nearestParentDartFrogProject(
      `${dartFrogPath}/fruits/pineapple.dart`,
    );
    assert.equal(result, undefined);
  });

  test("stops at the filesystem root", () => {
    fsStub.existsSync.returns(false);

    const root = path.parse(process.cwd()).root;
    const filePath = path.join(root, "a", "b", "c.dart");

    const result = nearestParentDartFrogProject(filePath);

    assert.equal(result, undefined);
    const checkedDirectories = fsStub.existsSync
      .getCalls()
      .map((call: any) => path.dirname(call.args[0]));
    assert.deepEqual(
      [...new Set(checkedDirectories)],
      [filePath, path.join(root, "a", "b"), path.join(root, "a"), root],
    );
  });

  test("returns the root when it is a Dart Frog project", () => {
    const root = path.parse(process.cwd()).root;
    const routesPath = path.join(root, "routes");
    const pubspecPath = path.join(root, "pubspec.yaml");

    fsStub.existsSync.withArgs(routesPath).returns(true);
    fsStub.existsSync.withArgs(pubspecPath).returns(true);
    fsStub.readFileSync
      .withArgs(pubspecPath, "utf-8")
      .returns(validPubspecYaml);

    assert.equal(
      nearestParentDartFrogProject(path.join(root, "routes", "index.dart")),
      root,
    );
  });

  suite("returns undefined for relative paths", () => {
    let traceStub: any;

    beforeEach(() => {
      traceStub = sinon.stub(console, "trace");
      fsStub.existsSync.returns(true);
      fsStub.readFileSync.returns(validPubspecYaml);
    });

    for (const relativePath of [
      "Untitled-1",
      "workingDirectory",
      "home/user/routes/index.dart",
      "extension-output-x#1",
      ".",
    ]) {
      test(`"${relativePath}"`, () => {
        const result = nearestParentDartFrogProject(relativePath);

        assert.equal(result, undefined);
        sinon.assert.notCalled(fsStub.existsSync);
        sinon.assert.calledOnce(traceStub);
      });
    }
  });
});

suite("nearestChildDartFrogProjects", () => {
  let fsStub: any;
  let nearestChildDartFrogProjects: any;

  beforeEach(() => {
    fsStub = {
      existsSync: sinon.stub(),
      readFileSync: sinon.stub(),
      statSync: sinon.stub(),
      readdirSync: sinon.stub(),
    };

    nearestChildDartFrogProjects = proxyquire(
      "../../../utils/dart-frog-project",
      {
        fs: fsStub,
      },
    ).nearestChildDartFrogProjects;
  });

  afterEach(() => {
    sinon.restore();
  });

  test("returns a single path when the file path is a Dart Frog project", () => {
    const filePath = "/home/project";

    const dartFrogPubspecRoutesPath = path.join(filePath, "routes");
    const dartFrogPubspecPath = path.join(filePath, "pubspec.yaml");
    fsStub.existsSync.withArgs(filePath).returns(true);
    fsStub.statSync.withArgs(filePath).returns({
      isDirectory: () => true,
    });
    fsStub.readdirSync.withArgs(filePath).returns([]);
    fsStub.existsSync.withArgs(dartFrogPubspecRoutesPath).returns(true);
    fsStub.existsSync.withArgs(dartFrogPubspecPath).returns(true);
    fsStub.readFileSync
      .withArgs(dartFrogPubspecPath, "utf-8")
      .returns(validPubspecYaml);

    const dartFrogProjects = nearestChildDartFrogProjects(filePath);

    assert.deepEqual(dartFrogProjects, [filePath]);
  });

  test("returns the path to all the child Dart Frog projects", () => {
    fsStub.existsSync.returns(false);

    const filePath = "/home/project";
    fsStub.existsSync.withArgs(filePath).returns(true);
    fsStub.statSync.withArgs(filePath).returns({
      isDirectory: () => true,
    });
    fsStub.readdirSync
      .withArgs(filePath)
      .returns(["file.dart", "frog1", "frog2", "subdirectory", "flutter"]);

    const fileDartPath = "/home/project/file.dart";
    fsStub.existsSync.withArgs(fileDartPath).returns(true);
    fsStub.statSync.withArgs(fileDartPath).returns({
      isDirectory: () => false,
    });

    const dartFrogPath1 = "/home/project/frog1";
    const dartFrogPubspecRoutesPath1 = path.join(dartFrogPath1, "routes");
    const dartFrogPubspecPath1 = path.join(dartFrogPath1, "pubspec.yaml");
    fsStub.existsSync.withArgs(dartFrogPath1).returns(true);
    fsStub.statSync.withArgs(dartFrogPath1).returns({
      isDirectory: () => true,
    });
    fsStub.readdirSync.withArgs(dartFrogPath1).returns([]);
    fsStub.existsSync.withArgs(dartFrogPubspecRoutesPath1).returns(true);
    fsStub.existsSync.withArgs(dartFrogPubspecPath1).returns(true);
    fsStub.readFileSync
      .withArgs(dartFrogPubspecPath1, "utf-8")
      .returns(validPubspecYaml);

    const dartFrogPath2 = "/home/project/frog2";
    const dartFrogPubspecRoutesPath2 = path.join(dartFrogPath2, "routes");
    const dartFrogPubspecPath2 = path.join(dartFrogPath2, "pubspec.yaml");
    fsStub.existsSync.withArgs(dartFrogPath2).returns(true);
    fsStub.statSync.withArgs(dartFrogPath2).returns({
      isDirectory: () => true,
    });
    fsStub.readdirSync.withArgs(dartFrogPath2).returns([]);
    fsStub.existsSync.withArgs(dartFrogPubspecRoutesPath2).returns(true);
    fsStub.existsSync.withArgs(dartFrogPubspecPath2).returns(true);
    fsStub.readFileSync
      .withArgs(dartFrogPubspecPath2, "utf-8")
      .returns(validPubspecYaml);

    const subdirectory = "/home/project/subdirectory";
    fsStub.existsSync.withArgs(subdirectory).returns(true);
    fsStub.statSync.withArgs(subdirectory).returns({
      isDirectory: () => true,
    });
    fsStub.readdirSync.withArgs(subdirectory).returns(["frog3"]);

    const dartFrogPath3 = "/home/project/subdirectory/frog3";
    const dartFrogPubspecRoutesPath3 = path.join(dartFrogPath3, "routes");
    const dartFrogPubspecPath3 = path.join(dartFrogPath3, "pubspec.yaml");
    fsStub.existsSync.withArgs(dartFrogPath3).returns(true);
    fsStub.statSync.withArgs(dartFrogPath3).returns({
      isDirectory: () => true,
    });
    fsStub.readdirSync.withArgs(dartFrogPath3).returns([]);
    fsStub.existsSync.withArgs(dartFrogPubspecRoutesPath3).returns(true);
    fsStub.existsSync.withArgs(dartFrogPubspecPath3).returns(true);
    fsStub.readFileSync
      .withArgs(dartFrogPubspecPath3, "utf-8")
      .returns(validPubspecYaml);

    const flutterPath = "/home/project/flutter";
    const flutterPubspecPath = path.join(flutterPath, "pubspec.yaml");
    fsStub.existsSync.withArgs(flutterPath).returns(true);
    fsStub.statSync.withArgs(flutterPath).returns({
      isDirectory: () => true,
    });
    fsStub.readdirSync.withArgs(flutterPath).returns([]);
    fsStub.existsSync.withArgs(flutterPubspecPath).returns(true);
    fsStub.readFileSync
      .withArgs(flutterPubspecPath, "utf-8")
      .returns(invalidPubspecYaml);

    const dartFrogProjects = nearestChildDartFrogProjects(filePath);

    assert.deepEqual(dartFrogProjects, [
      dartFrogPath1,
      dartFrogPath2,
      dartFrogPath3,
    ]);
  });

  suite("returns undefined", () => {
    test("when path does not exist", () => {
      const filePath = "/home/project/routes/animals/frog.dart";
      fsStub.existsSync.withArgs(filePath).returns(false);

      const result = nearestChildDartFrogProjects(filePath);

      assert.equal(result, undefined);
    });

    test("when path is not a directory", () => {
      const filePath = "/home/project/routes/animals/frog.dart";
      fsStub.existsSync.withArgs(filePath).returns(true);
      fsStub.statSync.withArgs(filePath).returns({
        isDirectory: () => false,
      });

      const result = nearestChildDartFrogProjects(filePath);

      assert.equal(result, undefined);
    });

    test("when subdirectory is not a Dart Frog project", () => {
      const filePath = "/home/project";
      fsStub.existsSync.withArgs(filePath).returns(true);
      fsStub.statSync.withArgs(filePath).returns({
        isDirectory: () => true,
      });
      fsStub.readdirSync.withArgs(filePath).returns(["frog"]);

      const dartFrogPath = "/home/project/frog";
      const dartFrogPubspecRoutesPath = path.join(dartFrogPath, "routes");
      const dartFrogPubspecPath = path.join(dartFrogPath, "pubspec.yaml");
      fsStub.existsSync.withArgs(dartFrogPath).returns(true);
      fsStub.statSync.withArgs(dartFrogPath).returns({
        isDirectory: () => true,
      });
      fsStub.readdirSync.withArgs(dartFrogPath).returns([]);
      fsStub.existsSync.withArgs(dartFrogPubspecRoutesPath).returns(true);
      fsStub.existsSync.withArgs(dartFrogPubspecPath).returns(true);
      fsStub.readFileSync
        .withArgs(dartFrogPubspecPath, "utf-8")
        .returns(invalidPubspecYaml);

      const result = nearestChildDartFrogProjects(filePath);

      assert.equal(result, undefined);
    });
  });
});

suite("isDartFrogProject", () => {
  let fsStub: any;
  let isDartFrogProject: any;

  beforeEach(() => {
    fsStub = {
      existsSync: sinon.stub(),
      readFileSync: sinon.stub(),
    };

    isDartFrogProject = proxyquire("../../../utils/dart-frog-project", {
      fs: fsStub,
    }).isDartFrogProject;
  });

  afterEach(() => {
    sinon.restore();
  });

  test("returns true if the file is at the root of a Dart Frog project", () => {
    const filePath = "/home/user";
    const routesPath = path.join(filePath, "routes");
    const pubspecPath = path.join(filePath, "pubspec.yaml");

    fsStub.existsSync.withArgs(routesPath).returns(true);
    fsStub.existsSync.withArgs(pubspecPath).returns(true);
    fsStub.readFileSync
      .withArgs(pubspecPath, "utf-8")
      .returns(validPubspecYaml);

    const result = isDartFrogProject(filePath);
    assert.equal(result, true);
  });

  suite("returns false", () => {
    test("if the file is missing a routes directory", () => {
      const filePath = "/home/user";
      const routesPath = path.join(filePath, "routes");
      const pubspecPath = path.join(filePath, "pubspec.yaml");

      fsStub.existsSync.withArgs(routesPath).returns(false);
      fsStub.existsSync.withArgs(pubspecPath).returns(true);

      const result = isDartFrogProject(filePath);
      assert.equal(result, false);
    });

    test("if the file is missing a pubspec.yaml file", () => {
      const filePath = "/home/user";
      const routesPath = path.join(filePath, "routes");
      const pubspecPath = path.join(filePath, "pubspec.yaml");

      fsStub.existsSync.withArgs(routesPath).returns(true);
      fsStub.existsSync.withArgs(pubspecPath).returns(false);

      const result = isDartFrogProject(filePath);
      assert.equal(result, false);
    });

    test("if the file is missing a dart_frog dependency", () => {
      const filePath = "/home/user";
      const routesPath = path.join(filePath, "routes");
      const pubspecPath = path.join(filePath, "pubspec.yaml");

      fsStub.existsSync.withArgs(routesPath).returns(true);
      fsStub.existsSync.withArgs(pubspecPath).returns(true);
      fsStub.readFileSync
        .withArgs(pubspecPath, "utf-8")
        .returns(invalidPubspecYaml);

      const result = isDartFrogProject(filePath);
      assert.equal(result, false);
    });

    test("if the file is missing a routes directory and a pubspec.yaml file", () => {
      const filePath = "/home/user";
      const routesPath = path.join(filePath, "routes");
      const pubspecPath = path.join(filePath, "pubspec.yaml");

      fsStub.existsSync.withArgs(routesPath).returns(false);
      fsStub.existsSync.withArgs(pubspecPath).returns(false);

      const result = isDartFrogProject(filePath);
      assert.equal(result, false);
    });
  });
});

suite("resolveDartFrogProjectPathFromWorkspaceFolders", () => {
  let resolveDartFrogProjectPathFromWorkspaceFolders: any;
  let vscodeStub: any;
  let nearestParentDartFrogProject: any;

  const projectUri = {
    uri: {
      fsPath: `home/project/`,
    },
  };

  beforeEach(() => {
    vscodeStub = {
      workspace: {
        workspaceFolders: sinon.stub(),
      },
    };

    resolveDartFrogProjectPathFromWorkspaceFolders = proxyquire(
      "../../../utils/dart-frog-project",
      {
        vscode: vscodeStub,
      },
    ).resolveDartFrogProjectPathFromWorkspaceFolders;

    nearestParentDartFrogProject = sinon.stub();
  });

  afterEach(() => {
    sinon.restore();
  });

  test("returns the path of the active worskpace folder when it is a Dart Frog project", () => {
    vscodeStub.workspace.workspaceFolders = [projectUri];
    nearestParentDartFrogProject
      .withArgs(projectUri.uri.fsPath)
      .returns(projectUri.uri.fsPath);

    const dartFrogProjectPath = resolveDartFrogProjectPathFromWorkspaceFolders(
      nearestParentDartFrogProject,
    );

    assert.deepEqual(dartFrogProjectPath, [projectUri.uri.fsPath]);
  });

  suite("returns undefined", () => {
    test("when there is no active workspace folder", () => {
      vscodeStub.workspace.workspaceFolders = [];

      const dartFrogProjectPath =
        resolveDartFrogProjectPathFromWorkspaceFolders(
          nearestParentDartFrogProject,
        );

      assert.deepEqual(dartFrogProjectPath, undefined);
    });

    test("when there is no active Dart Frog workspace folder", () => {
      vscodeStub.workspace.workspaceFolders = [projectUri];
      nearestParentDartFrogProject
        .withArgs(projectUri.uri.fsPath)
        .returns(undefined);

      const dartFrogProjectPath =
        resolveDartFrogProjectPathFromWorkspaceFolders(
          nearestParentDartFrogProject,
        );

      assert.deepEqual(dartFrogProjectPath, undefined);
    });
  });
});

suite("resolveDartFrogProjectPathFromActiveTextEditor", () => {
  let resolveDartFrogProjectPathFromActiveTextEditor: any;
  let vscodeStub: any;
  let nearestParentDartFrogProject: any;

  beforeEach(() => {
    vscodeStub = {
      window: {
        activeTextEditor: sinon.stub(),
      },
    };

    resolveDartFrogProjectPathFromActiveTextEditor = proxyquire(
      "../../../utils/dart-frog-project",
      {
        vscode: vscodeStub,
      },
    ).resolveDartFrogProjectPathFromActiveTextEditor;

    nearestParentDartFrogProject = sinon.stub();
  });

  afterEach(() => {
    sinon.restore();
  });

  test("returns the path of the active text editor when it is a Dart Frog Dart route file", () => {
    const projectUri = {
      uri: {
        fsPath: `home/project/routes/index.dart`,
      },
    };
    vscodeStub.window.activeTextEditor = {
      document: projectUri,
    };
    nearestParentDartFrogProject
      .withArgs(projectUri.uri.fsPath)
      .returns(`home/project`);

    const dartFrogProjectPath = resolveDartFrogProjectPathFromActiveTextEditor(
      nearestParentDartFrogProject,
    );

    assert.deepEqual(dartFrogProjectPath, projectUri.uri.fsPath);
  });

  suite("returns undefined", () => {
    test("when there is no active text editor", () => {
      vscodeStub.window.activeTextEditor = undefined;

      const dartFrogProjectPath =
        resolveDartFrogProjectPathFromActiveTextEditor(
          nearestParentDartFrogProject,
        );

      assert.deepEqual(dartFrogProjectPath, undefined);
    });

    test("when there is an active text editor that is not a Dart file", () => {
      const projectUri = {
        uri: {
          fsPath: `home/project/routes/index.py`,
        },
      };
      vscodeStub.window.activeTextEditor = {
        document: projectUri,
      };
      nearestParentDartFrogProject
        .withArgs(projectUri.uri.fsPath)
        .returns(projectUri.uri.fsPath);

      const dartFrogProjectPath =
        resolveDartFrogProjectPathFromActiveTextEditor(
          nearestParentDartFrogProject,
        );

      assert.deepEqual(dartFrogProjectPath, undefined);
    });

    test("when there is an active text editor that is not a Dart Frog route file", () => {
      const projectUri = {
        uri: {
          fsPath: `home/project/not-routes/index.dart`,
        },
      };
      vscodeStub.window.activeTextEditor.document = projectUri;
      nearestParentDartFrogProject
        .withArgs(projectUri.uri.fsPath)
        .returns(projectUri.uri.fsPath);

      const dartFrogProjectPath =
        resolveDartFrogProjectPathFromActiveTextEditor(
          nearestParentDartFrogProject,
        );

      assert.deepEqual(dartFrogProjectPath, undefined);
    });
  });
});

suite("quickPickProject", () => {
  let vscodeStub: any;
  let quickPickProject: any;
  let quickPick: any;

  const projectPath1 = "home/project1";
  const projectPath2 = "home/project2";

  beforeEach(() => {
    vscodeStub = {
      window: {
        createQuickPick: sinon.stub(),
      },
    };

    quickPickProject = proxyquire("../../../utils/dart-frog-project", {
      vscode: vscodeStub,
    }).quickPickProject;

    quickPick = sinon.stub();
    vscodeStub.window.createQuickPick.returns(quickPick);
    quickPick.show = sinon.stub();
    quickPick.dispose = sinon.stub();
    quickPick.onDidChangeSelection = sinon.stub();
  });

  afterEach(() => {
    sinon.restore();
  });

  test("returns undefined when there are no project paths", async () => {
    const project = await quickPickProject({}, []);

    assert.strictEqual(project, undefined);
    sinon.assert.neverCalledWith(quickPick.show, sinon.match.any);
  });

  test("returns the only project path when there is a single project path", async () => {
    const project = await quickPickProject({}, [projectPath1]);

    assert.strictEqual(project, projectPath1);
    sinon.assert.neverCalledWith(quickPick.show, sinon.match.any);
  });

  suite("placeholder", () => {
    test("is defined by default", async () => {
      const project = quickPickProject({}, [projectPath1, projectPath2]);

      const onDidChangeSelection =
        quickPick.onDidChangeSelection.getCall(0).args[0];
      onDidChangeSelection([]);

      await project;

      assert.strictEqual(quickPick.placeholder, "Select a Dart Frog project");
    });

    test("can be overridden", async () => {
      const placeHolder = "placeholder";
      const project = quickPickProject(
        {
          placeHolder,
        },
        [projectPath1, projectPath2],
      );

      const onDidChangeSelection =
        quickPick.onDidChangeSelection.getCall(0).args[0];
      onDidChangeSelection([]);

      await project;

      assert.strictEqual(quickPick.placeholder, placeHolder);
    });
  });

  suite("ignoreFocusOut", () => {
    test("is true by default", async () => {
      const project = quickPickProject({}, [projectPath1, projectPath2]);

      const onDidChangeSelection =
        quickPick.onDidChangeSelection.getCall(0).args[0];
      onDidChangeSelection([]);

      await project;

      assert.strictEqual(quickPick.ignoreFocusOut, true);
    });

    test("can be overridden", async () => {
      const ignoreFocusOut = false;
      const project = quickPickProject(
        {
          ignoreFocusOut,
        },
        [projectPath1, projectPath2],
      );

      const onDidChangeSelection =
        quickPick.onDidChangeSelection.getCall(0).args[0];
      onDidChangeSelection([]);

      await project;

      assert.strictEqual(quickPick.ignoreFocusOut, ignoreFocusOut);
    });
  });

  suite("canSelectMany", () => {
    test("is false by default", async () => {
      const project = quickPickProject({}, [projectPath1, projectPath2]);

      const onDidChangeSelection =
        quickPick.onDidChangeSelection.getCall(0).args[0];
      onDidChangeSelection([]);

      await project;

      assert.strictEqual(quickPick.canSelectMany, false);
    });

    test("can be overridden", async () => {
      const canPickMany = true;
      const project = quickPickProject(
        {
          canPickMany,
        },
        [projectPath1, projectPath2],
      );

      const onDidChangeSelection =
        quickPick.onDidChangeSelection.getCall(0).args[0];
      onDidChangeSelection([]);

      await project;

      assert.strictEqual(quickPick.canSelectMany, canPickMany);
    });
  });

  test("busy is false by default", async () => {
    const project = quickPickProject({}, [projectPath1, projectPath2]);

    const onDidChangeSelection =
      quickPick.onDidChangeSelection.getCall(0).args[0];
    onDidChangeSelection([]);

    await project;

    assert.strictEqual(quickPick.busy, false);
  });

  test("shows appropiate items for resolved projects", async () => {
    const project = quickPickProject({}, [projectPath1, projectPath2]);

    const onDidChangeSelection =
      quickPick.onDidChangeSelection.getCall(0).args[0];
    onDidChangeSelection([]);

    await project;

    const items = quickPick.items;

    sinon.assert.match(items[0], {
      label: `$(dart-frog) project1`,
      description: projectPath1,
      projectPath: projectPath1,
    });
    sinon.assert.match(items[1], {
      label: `$(dart-frog) project2`,
      description: projectPath2,
      projectPath: projectPath2,
    });
  });

  test("shows the quick pick", async () => {
    const project = quickPickProject({}, [projectPath1, projectPath2]);

    const onDidChangeSelection =
      quickPick.onDidChangeSelection.getCall(0).args[0];
    onDidChangeSelection([]);

    await project;

    sinon.assert.calledOnce(quickPick.show);
  });

  suite("onDidSelectItem", () => {
    test("is called when an item is selected", async () => {
      const onDidSelectItem = sinon.stub();
      const project = quickPickProject(
        {
          onDidSelectItem,
        },
        [projectPath1, projectPath2],
      );

      const onDidChangeSelection =
        quickPick.onDidChangeSelection.getCall(0).args[0];
      onDidChangeSelection([{ projectPath: projectPath1 }]);

      await project;

      sinon.assert.calledOnceWithExactly(onDidSelectItem, {
        projectPath: projectPath1,
      });
    });

    test("is not called when an item is dismissed", async () => {
      const onDidSelectItem = sinon.stub();
      const project = quickPickProject(
        {
          onDidSelectItem,
        },
        [projectPath1, projectPath2],
      );

      const onDidChangeSelection =
        quickPick.onDidChangeSelection.getCall(0).args[0];
      onDidChangeSelection(undefined);

      await project;

      sinon.assert.notCalled(onDidSelectItem);
    });
  });

  suite("dispose", () => {
    test("is called when an item is selected", async () => {
      const project = quickPickProject({}, [projectPath1, projectPath2]);

      const onDidChangeSelection =
        quickPick.onDidChangeSelection.getCall(0).args[0];
      onDidChangeSelection([{ projectPath: projectPath1 }]);

      await project;

      sinon.assert.calledOnce(quickPick.dispose);
    });

    test("is called when an item is dismissed", async () => {
      const project = quickPickProject({}, [projectPath1, projectPath2]);

      const onDidChangeSelection =
        quickPick.onDidChangeSelection.getCall(0).args[0];
      onDidChangeSelection(undefined);

      await project;

      sinon.assert.calledOnce(quickPick.dispose);
    });
  });

  suite("returns", () => {
    test("undefined when dismissed", async () => {
      const project = quickPickProject({}, [projectPath1, projectPath2]);

      const onDidChangeSelection =
        quickPick.onDidChangeSelection.getCall(0).args[0];
      onDidChangeSelection(undefined);

      const selection = await project;

      assert.strictEqual(selection, undefined);
    });

    test("application when selected", async () => {
      const project = quickPickProject({}, [projectPath1, projectPath2]);

      const onDidChangeSelection =
        quickPick.onDidChangeSelection.getCall(0).args[0];
      onDidChangeSelection([{ projectPath: projectPath1 }]);

      const selection = await project;

      assert.strictEqual(selection, projectPath1);
    });
  });
});

/**
 * Example of a pubspec.yaml file that depends on Dart Frog.
 *
 * This is used to verify that the `isDartFrogProject` function works as
 * expected. Which uses a heuristic to determine if a file is in a Dart Frog
 * project based on it containing a `dart_frog` subsstring.
 */
const validPubspecYaml = `
name: sample
description: An new Dart Frog application
version: 1.0.0+1
publish_to: none

environment:
  sdk: ">=2.19.0 <3.0.0"

dependencies:
  dart_frog: ^0.3.0

dev_dependencies:
  test: ^1.19.2
  very_good_analysis: ^5.0.0
`;

/**
 * Example of a pubspec.yaml file, that does not depend on Dart Frog.
 *
 * This is used to verify that the `isDartFrogProject` function works as
 * expected. Which uses a heuristic to determine if a file is in a Dart Frog
 * project based on it containing a `dart_frog` subsstring.
 */
const invalidPubspecYaml = `
name: sample
description: An new Dart Frog application
version: 1.0.0+1
publish_to: none

environment:
  sdk: ">=2.19.0 <3.0.0"

dependencies:
  dart_bird: ^0.3.0

dev_dependencies:
  test: ^1.19.2
  very_good_analysis: ^5.0.0
`;
