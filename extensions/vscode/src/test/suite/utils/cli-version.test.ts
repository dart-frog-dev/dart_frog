const sinon = require("sinon");
var proxyquire = require("proxyquire");

import * as assert from "assert";
import { afterEach, beforeEach } from "mocha";

suite("readDartFrogCLIVersion", () => {
  let cpStub: any;
  let cliVersion: any;

  beforeEach(() => {
    cpStub = {
      execSync: sinon.stub(),
    };

    cliVersion = proxyquire("../../../utils/cli-version", {
      // eslint-disable-next-line @typescript-eslint/naming-convention
      child_process: cpStub,
    });
  });

  afterEach(() => {
    sinon.restore();
  });

  suite(
    "returns the version of Dart Frog CLI installed in the user's system",
    () => {
      test("when on latest version", () => {
        const dartFrogVersionCommandResult = "1.1.1\n";
        const encodedDartFrogVersionCommandResult = new TextEncoder().encode(
          dartFrogVersionCommandResult
        );
        cpStub.execSync.returns(encodedDartFrogVersionCommandResult);

        assert.strictEqual(cliVersion.readDartFrogCLIVersion(), "1.1.1");
      });

      test("when new version is available", () => {
        const dartFrogVersionCommandResult = `1.1.1

        Update available! 1.1.1 → 1.1.2
        Changelog: \u001b]8;;https://github.com/dart-frog-dev/dart_frog/releases/tag/dart_frog_cli-v1.1.2\u001b\\https://github.com/dart-frog-dev/dart_frog/releases/tag/dart_frog_cli-v1.1.2\u001b]8;;\u001b\\
        Run dart_frog update to update
        `;
        const encodedDartFrogVersionCommandResult = new TextEncoder().encode(
          dartFrogVersionCommandResult
        );
        cpStub.execSync.returns(encodedDartFrogVersionCommandResult);

        assert.strictEqual(cliVersion.readDartFrogCLIVersion(), "1.1.1");
      });
    }
  );

  test("returns undefined if Dart Frog CLI is not installed", () => {
    cpStub.execSync.throws();

    assert.strictEqual(cliVersion.readDartFrogCLIVersion(), undefined);
  });
});

suite("readLatestDartFrogCLIVersion", () => {
  let cpStub: any;
  let cliVersion: any;

  beforeEach(() => {
    cpStub = {
      execSync: sinon.stub(),
    };

    cliVersion = proxyquire("../../../utils/cli-version", {
      // eslint-disable-next-line @typescript-eslint/naming-convention
      child_process: cpStub,
    });
  });

  afterEach(() => {
    sinon.restore();
  });

  suite("returns the latest version of Dart Frog CLI", () => {
    test("when on latest version", () => {
      const dartFrogVersionCommandResult = "1.1.2\n";
      const encodedDartFrogVersionCommandResult = new TextEncoder().encode(
        dartFrogVersionCommandResult
      );
      cpStub.execSync.returns(encodedDartFrogVersionCommandResult);

      assert.strictEqual(cliVersion.readLatestDartFrogCLIVersion(), "1.1.2");
    });

    test("when new version is available", () => {
      const dartFrogVersionCommandResult = `1.1.1

        Update available! 1.1.1 → 1.1.2
        Changelog: \u001b]8;;https://github.com/dart-frog-dev/dart_frog/releases/tag/dart_frog_cli-v1.1.2\u001b\\https://github.com/dart-frog-dev/dart_frog/releases/tag/dart_frog_cli-v1.1.2\u001b]8;;\u001b\\
        Run dart_frog update to update
        `;
      const encodedDartFrogVersionCommandResult = new TextEncoder().encode(
        dartFrogVersionCommandResult
      );
      cpStub.execSync.returns(encodedDartFrogVersionCommandResult);

      assert.strictEqual(cliVersion.readLatestDartFrogCLIVersion(), "1.1.2");
    });
  });

  test("returns undefined if Dart Frog CLI is not installed", () => {
    cpStub.execSync.throws();

    assert.strictEqual(cliVersion.readLatestDartFrogCLIVersion(), undefined);
  });
});

suite("isCompatibleDartFrogCLIVersion", () => {
  let cliVersion: any;

  beforeEach(() => {
    cliVersion = proxyquire("../../../utils/cli-version", {});
  });

  test("returns true if the version of Dart Frog CLI installed in the user's system is compatible with this extension", () => {
    assert.strictEqual(
      cliVersion.isCompatibleDartFrogCLIVersion("1.1.1"),
      true
    );
    assert.strictEqual(
      cliVersion.isCompatibleDartFrogCLIVersion("1.1.2"),
      true
    );
  });

  test("returns false if the version of Dart Frog CLI installed in the user's system is not compatible with this extension", () => {
    assert.strictEqual(
      cliVersion.isCompatibleDartFrogCLIVersion("2.0.0"),
      false
    );
    assert.strictEqual(
      cliVersion.isCompatibleDartFrogCLIVersion("0.3.8"),
      false
    );
  });
});

suite("openChangelog", () => {
  let vscodeStub: any;
  let cliVersion: any;

  beforeEach(() => {
    vscodeStub = {
      commands: {
        executeCommand: sinon.stub(),
      },
      // eslint-disable-next-line @typescript-eslint/naming-convention
      Uri: {
        parse: sinon.stub(),
      },
    };

    cliVersion = proxyquire("../../../utils/cli-version", {
      vscode: vscodeStub,
    });
  });

  afterEach(() => {
    sinon.restore();
  });

  test("triggers vscode.open command with correct url", async () => {
    const version = "0.0.0";
    const url = "https://github.com";
    vscodeStub.Uri.parse.returns(url);

    await cliVersion.openChangelog(version);

    sinon.assert.calledOnceWithExactly(
      vscodeStub.commands.executeCommand,
      "vscode.open",
      url
    );
  });
});
