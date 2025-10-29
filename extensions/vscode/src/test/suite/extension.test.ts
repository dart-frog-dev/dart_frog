const sinon = require("sinon");
var proxyquire = require("proxyquire");

import * as assert from "assert";
import * as vscode from "vscode";
import {
  DebugOnRequestCodeLensProvider,
  RunOnRequestCodeLensProvider,
} from "../../code-lens";
import { afterEach, beforeEach } from "mocha";
import { installCLI, newMiddleware, newRoute, updateCLI } from "../../commands";

suite("activate", () => {
  let vscodeStub: any;
  let utilsStub: any;
  let extension: any;
  let context: any;

  beforeEach(() => {
    vscodeStub = {
      commands: {
        registerCommand: sinon.stub(),
        executeCommand: sinon.stub(),
      },
      languages: {
        registerCodeLensProvider: sinon.stub(),
      },
      window: {
        onDidChangeActiveTextEditor: sinon.stub(),
      },
      workspace: {
        onDidChangeWorkspaceFolders: sinon.stub(),
      },
    };

    utilsStub = {
      readDartFrogCLIVersion: sinon.stub(),
      isCompatibleDartFrogCLIVersion: sinon.stub(),
      isDartFrogCLIInstalled: sinon.stub(),
      canResolveDartFrogProjectPath: sinon.stub(),
      suggestInstallingDartFrogCLI: sinon.stub(),
    };
    utilsStub.readDartFrogCLIVersion.returns("0.0.0");
    utilsStub.isCompatibleDartFrogCLIVersion.returns(true);
    utilsStub.isDartFrogCLIInstalled.returns(true);
    utilsStub.canResolveDartFrogProjectPath.returns(true);

    const childProcessStub = {
      execSync: sinon.stub(),
    };

    extension = proxyquire("../../extension", {
      vscode: vscodeStub,
      // eslint-disable-next-line @typescript-eslint/naming-convention
      child_process: childProcessStub,
      // eslint-disable-next-line @typescript-eslint/naming-convention
      "./utils": utilsStub,
    });
    context = { subscriptions: [] };
  });

  afterEach(() => {
    sinon.restore();
  });

  test("does not throw", async () => {
    const extension = vscode.extensions.getExtension(
      "DartFrog.dart-frog-dev"
    ) as vscode.Extension<any>;

    assert.doesNotThrow(async () => await extension.activate());
  });

  suite("registers CodeLens", () => {
    test("DebugOnRequestCodeLensProvider on dart", () => {
      extension.activate(context);

      sinon.assert.calledWith(
        vscodeStub.languages.registerCodeLensProvider,
        "dart",
        sinon.match.any
      );

      const provider =
        vscodeStub.languages.registerCodeLensProvider.getCall(0).args[1];

      assert.ok(provider instanceof DebugOnRequestCodeLensProvider);
    });

    test("RunOnRequestCodeLensProvider on dart", () => {
      extension.activate(context);

      sinon.assert.calledWith(
        vscodeStub.languages.registerCodeLensProvider,
        "dart",
        sinon.match.any
      );

      const provider =
        vscodeStub.languages.registerCodeLensProvider.getCall(1).args[1];

      assert.ok(provider instanceof RunOnRequestCodeLensProvider);
    });

    test("in the correct order", () => {
      // Registration order matters for CodeLensProviders reporting on the same
      // word; since it will alter the order in which they are displayed in the
      // editor. Those registered first will be rightmost in the editor.
      extension.activate(context);

      const provider1 =
        vscodeStub.languages.registerCodeLensProvider.getCall(0).args[1];
      const provider2 =
        vscodeStub.languages.registerCodeLensProvider.getCall(1).args[1];

      assert.ok(provider1 instanceof DebugOnRequestCodeLensProvider);
      assert.ok(provider2 instanceof RunOnRequestCodeLensProvider);
    });
  });

  suite("registers command", () => {
    test("install-cli", () => {
      extension.activate(context);

      sinon.assert.calledWith(
        vscodeStub.commands.registerCommand,
        "dart-frog.install-cli",
        installCLI
      );
    });

    test("update-cli", () => {
      extension.activate(context);

      sinon.assert.calledWith(
        vscodeStub.commands.registerCommand,
        "dart-frog.update-cli",
        updateCLI
      );
    });

    test("new-route", () => {
      extension.activate(context);

      sinon.assert.calledWith(
        vscodeStub.commands.registerCommand,
        "dart-frog.new-route",
        newRoute
      );
    });

    test("new-middleware", () => {
      extension.activate(context);

      sinon.assert.calledWith(
        vscodeStub.commands.registerCommand,
        "dart-frog.new-middleware",
        newMiddleware
      );
    });
  });

  test("calls suggestInstallingDartFrogCLI when Dart Frog CLI is not installed", () => {
    utilsStub.isDartFrogCLIInstalled.returns(false);

    const context = { subscriptions: [] };
    const ensureCompatibleCLI = sinon.stub();
    extension.activate(context, ensureCompatibleCLI);

    sinon.assert.calledOnce(utilsStub.suggestInstallingDartFrogCLI);
  });

  test("calls ensureCompatibleDartFrogCLI when Dart Frog CLI is installed", () => {
    utilsStub.isDartFrogCLIInstalled.returns(true);

    const context = { subscriptions: [] };
    const ensureCompatibleCLI = sinon.stub();
    extension.activate(context, ensureCompatibleCLI);

    sinon.assert.calledOnce(ensureCompatibleCLI);
  });

  suite("sets anyDartFrogProjectLoaded", () => {
    suite("to true", () => {
      test("when can resolve Dart Frog project", () => {
        utilsStub.canResolveDartFrogProjectPath.returns(true);

        const context = { subscriptions: [] };
        extension.activate(context);

        sinon.assert.calledWith(
          vscodeStub.commands.executeCommand,
          "setContext",
          "dart-frog:anyDartFrogProjectLoaded",
          true
        );
      });

      test("when active text editor changes to a Dart Frog project", () => {
        utilsStub.canResolveDartFrogProjectPath.returns(false);

        const context = { subscriptions: [] };
        extension.activate(context);

        utilsStub.canResolveDartFrogProjectPath.returns(true);
        vscodeStub.window.onDidChangeActiveTextEditor.getCall(0).args[0]();

        sinon.assert.calledWith(
          vscodeStub.commands.executeCommand,
          "setContext",
          "dart-frog:anyDartFrogProjectLoaded",
          true
        );
      });

      test("when workspace folder changes to a Dart Frog project", () => {
        utilsStub.canResolveDartFrogProjectPath.returns(false);

        const context = { subscriptions: [] };
        extension.activate(context);

        utilsStub.canResolveDartFrogProjectPath.returns(true);
        vscodeStub.workspace.onDidChangeWorkspaceFolders.getCall(0).args[0]();

        sinon.assert.calledWith(
          vscodeStub.commands.executeCommand,
          "setContext",
          "dart-frog:anyDartFrogProjectLoaded",
          true
        );
      });
    });

    suite("to false", () => {
      test("when can not resolve Dart Frog project", () => {
        utilsStub.canResolveDartFrogProjectPath.returns(false);

        const context = { subscriptions: [] };
        extension.activate(context);

        sinon.assert.calledWith(
          vscodeStub.commands.executeCommand,
          "setContext",
          "dart-frog:anyDartFrogProjectLoaded",
          false
        );
      });

      test("when active text editor changes and is not a Dart Frog project", () => {
        utilsStub.canResolveDartFrogProjectPath.returns(true);

        const context = { subscriptions: [] };
        extension.activate(context);

        utilsStub.canResolveDartFrogProjectPath.returns(false);
        vscodeStub.window.onDidChangeActiveTextEditor.getCall(0).args[0]();

        sinon.assert.calledWith(
          vscodeStub.commands.executeCommand,
          "setContext",
          "dart-frog:anyDartFrogProjectLoaded",
          false
        );
      });

      test("when workspace folder changes and is not a Dart Frog project", () => {
        utilsStub.canResolveDartFrogProjectPath.returns(true);

        const context = { subscriptions: [] };
        extension.activate(context);

        utilsStub.canResolveDartFrogProjectPath.returns(false);
        vscodeStub.workspace.onDidChangeWorkspaceFolders.getCall(0).args[0]();

        sinon.assert.calledWith(
          vscodeStub.commands.executeCommand,
          "setContext",
          "dart-frog:anyDartFrogProjectLoaded",
          false
        );
      });
    });
  });
});

suite("ensureCompatibleDartFrogCLI", () => {
  let vscodeStub: any;
  let utilsStub: any;
  let commandsStub: any;
  let extension: any;

  beforeEach(() => {
    vscodeStub = {
      window: {
        showWarningMessage: sinon.stub(),
      },
    };

    utilsStub = {
      readDartFrogCLIVersion: sinon.stub(),
      isCompatibleDartFrogCLIVersion: sinon.stub(),
      readLatestDartFrogCLIVersion: sinon.stub(),
      openChangelog: sinon.stub(),
    };
    commandsStub = {
      updateCLI: sinon.stub(),
    };

    extension = proxyquire("../../extension", {
      vscode: vscodeStub,
      // eslint-disable-next-line @typescript-eslint/naming-convention
      "./utils": utilsStub,
      // eslint-disable-next-line @typescript-eslint/naming-convention
      "./commands": commandsStub,
    });
  });

  afterEach(() => {
    sinon.restore();
  });

  test("does not show warning when CLI is not installed", async () => {
    utilsStub.readDartFrogCLIVersion.returns(undefined);

    await extension.ensureCompatibleDartFrogCLI();

    sinon.assert.notCalled(vscodeStub.window.showWarningMessage);
  });

  test("does not show warning when CLI is compatible", async () => {
    utilsStub.readDartFrogCLIVersion.returns("1.0.0");
    utilsStub.isCompatibleDartFrogCLIVersion.returns(true);

    await extension.ensureCompatibleDartFrogCLI();

    sinon.assert.notCalled(vscodeStub.window.showWarningMessage);
  });

  test("does not show warning when latest version cannot be retrieved", async () => {
    utilsStub.readDartFrogCLIVersion.returns("1.0.0");
    utilsStub.isCompatibleDartFrogCLIVersion.returns(false);
    utilsStub.readLatestDartFrogCLIVersion.returns(undefined);

    await extension.ensureCompatibleDartFrogCLI();

    sinon.assert.notCalled(vscodeStub.window.showWarningMessage);
  });

  suite("incompatible CLI", () => {
    const version = "0.0.0";
    const latestVersion = "2.0.0";

    beforeEach(() => {
      utilsStub.readDartFrogCLIVersion.returns(version);
      utilsStub.readLatestDartFrogCLIVersion.returns(latestVersion);
      utilsStub.isCompatibleDartFrogCLIVersion.withArgs(version).returns(false);
      utilsStub.isCompatibleDartFrogCLIVersion
        .withArgs(latestVersion)
        .returns(true);
    });

    afterEach(() => {
      sinon.restore();
    });

    test("shows warning", async () => {
      await extension.ensureCompatibleDartFrogCLI();

      sinon.assert.calledOnceWithExactly(
        vscodeStub.window.showWarningMessage,
        `Dart Frog CLI version ${version} is not compatible with this extension.`,
        "Update Dart Frog CLI",
        "Changelog",
        "Ignore"
      );
    });

    test("shows warning without update action when latest version is not compatible", async () => {
      utilsStub.isCompatibleDartFrogCLIVersion
        .withArgs(latestVersion)
        .returns(false);

      await extension.ensureCompatibleDartFrogCLI();

      sinon.assert.calledOnceWithExactly(
        vscodeStub.window.showWarningMessage,
        `Dart Frog CLI version ${version} is not compatible with this extension.`,
        "Changelog",
        "Ignore"
      );
    });

    test("updates CLI when selected", async () => {
      vscodeStub.window.showWarningMessage.returns("Update Dart Frog CLI");

      await extension.ensureCompatibleDartFrogCLI();

      sinon.assert.calledOnce(commandsStub.updateCLI);
    });

    test("opens changelog when selected", async () => {
      vscodeStub.window.showWarningMessage.returns("Changelog");

      await extension.ensureCompatibleDartFrogCLI();

      sinon.assert.calledOnceWithExactly(
        utilsStub.openChangelog,
        latestVersion
      );
      sinon.assert.notCalled(commandsStub.updateCLI);
    });

    test("does not update CLI when ignored", async () => {
      vscodeStub.window.showWarningMessage.returns("Ignore");

      await extension.ensureCompatibleDartFrogCLI();

      sinon.assert.notCalled(commandsStub.updateCLI);
    });
  });
});
