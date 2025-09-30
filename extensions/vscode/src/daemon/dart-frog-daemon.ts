import {
  AscendingNumericalIdentifierGenerator,
  IdentifierGenerator,
} from "../utils";
import { ChildProcessWithoutNullStreams, spawn } from "child_process";
import {
  DaemonEvent,
  DaemonMessage,
  DaemonRequest,
  DaemonResponse,
  isDaemonEvent,
  isDaemonRequest,
  isDaemonResponse,
  isReadyDaemonEvent,
} from "./protocol";
import { DartFrogApplicationRegistry } from ".";
import { EventEmitter } from "events";

/**
 * An error that is thrown when the Dart Frog Daemon has not yet been invoked
 * but a request is made to it.
 */
export class DartFrogDaemonNotInvokedError extends Error {
  constructor() {
    super("The Dart Frog Daemon is yet to be invoked.");
  }
}

/**
 * An error that is thrown when the Dart Frog Daemon is invoked but is not yet
 * ready to accept requests.
 */
export class DartFrogDaemonReadyError extends Error {
  constructor() {
    super("The Dart Frog Daemon is not yet ready to accept requests.");
  }
}

/**
 * The types of events that are emitted by the {@link DartFrogDaemon}.
 *
 * The possible types of events are:
 * - "request": When a request is sent to the Dart Frog daemon. The
 * {@link DaemonRequest} is passed as an argument to the event handler.
 * - "response": When a response is received from the Dart Frog daemon. The
 * {@link DaemonResponse} is passed as an argument to the event handler.
 * - "event": When an event is received from the Dart Frog daemon. The
 * {@link DaemonEvent} is passed as an argument to the event handler.
 */
export enum DartFrogDaemonEventEmitterTypes {
  request = "request",
  response = "response",
  event = "event",
}

/**
 * The Dart Frog daemon is a long-running process that is responsible for
 * managing a single or multiple Dart Frog projects simultaneously.
 *
 * @see {@link https://dart-frog.dev/advanced/daemon Dart Frog daemon documentation }
 */
export class DartFrogDaemon {
  private static _instance: DartFrogDaemon;

  /**
   * A singleton instance of the Dart Frog daemon.
   *
   * A Dart Frog daemon can manage multiple Dart Frog projects simultaneously.
   */
  public static get instance() {
    return this._instance || (this._instance = new this());
  }

  /**
   * Generates unique and valid identifiers for requests.
   *
   * Should not be used as a request counter, since it is not guaranteed to
   * be called the same number of times as the number of requests sent.
   */
  public readonly requestIdentifierGenerator: IdentifierGenerator =
    new AscendingNumericalIdentifierGenerator();

  private daemonMessagesEventEmitter = new EventEmitter();

  /**
   * The process that is running the Dart Frog daemon.
   *
   * Undefined until the Dart Frog daemon is {@link invoke}d.
   */
  private process: ChildProcessWithoutNullStreams | undefined;

  /**
   * A registry of the Dart Frog applications that are currently running on
   * this Dart Frog daemon.
   */
  public readonly applicationRegistry: DartFrogApplicationRegistry =
    new DartFrogApplicationRegistry(this);

  private _isReady: boolean = false;

  /**
   * Whether the Dart Frog daemon is ready to accept requests.
   *
   * The Dart Frog daemon is ready to accept requests when it has emmitted
   * the "ready" event after being {@link invoke}d.
   *
   * @see {@link invoke} to invoke the Dart Frog daemon.
   */
  public get isReady(): boolean {
    return this._isReady;
  }

  /**
   * Invokes the Dart Frog daemon.
   *
   * If the Dart Frog daemon is already running, this method will immediately
   * return.
   *
   * After invoking the Dart Frog daemon, it will be ready to accept requests.
   *
   * @param workingDirectory The working directory of the Dart Frog daemon,
   * usually the root directory of the Dart Frog project.
   */
  public async invoke(workingDirectory: string): Promise<void> {
    if (this.isReady || this.process) {
      return Promise.resolve();
    }

    const readyPromise = new Promise<void>((resolve) => {
      const readyEventListener = (message: DaemonEvent) => {
        if (!this._isReady && isReadyDaemonEvent(message)) {
          this._isReady = true;
          this.off(DartFrogDaemonEventEmitterTypes.event, readyEventListener);
          resolve();
        }
      };
      this.on(
        DartFrogDaemonEventEmitterTypes.event,
        readyEventListener.bind(this)
      );
    });

    this.process = spawn("dart_frog", ["daemon"], {
      cwd: workingDirectory,
      shell: true,
    });
    this.process.stdout.on("data", this.stdoutDataListener.bind(this));

    return readyPromise;
  }

  /**
   * Decodes the stdout and emits events accordingly via the
   * {@link daemonMessagesEventEmitter}.
   *
   * @param data The data that was received from the stdout of the Dart Frog
   * Daemon.
   * @see {@link daemonMessagesEventEmitter} for listening to the events that
   * are emitted.
   */
  private stdoutDataListener(data: Buffer): void {
    const daemonMessages = DaemonMessage.decode(data);
    for (const message of daemonMessages) {
      if (isDaemonEvent(message)) {
        this.daemonMessagesEventEmitter.emit(
          DartFrogDaemonEventEmitterTypes.event,
          message
        );
      } else if (isDaemonResponse(message)) {
        this.daemonMessagesEventEmitter.emit(
          DartFrogDaemonEventEmitterTypes.response,
          message
        );
      } else if (isDaemonRequest(message)) {
        this.daemonMessagesEventEmitter.emit(
          DartFrogDaemonEventEmitterTypes.request,
          message
        );
      }
    }
  }

  /**
   * Starts listening to events related to this Dart Frog daemon.
   *
   * @returns A reference to this Dart Frog daemon, so that calls can be
   * chained.
   * @see {@link DartFrogDaemonEventEmitterTypes} for the types of events that
   * are emitted.
   */
  public on(
    type: DartFrogDaemonEventEmitterTypes,
    listener: (...args: any[]) => void
  ): DartFrogDaemon {
    this.daemonMessagesEventEmitter.on(type, listener);
    return this;
  }

  /**
   * Unsubscribes a listener from events related to this Dart Frog daemon.
   *
   * @param type The type of event to unsubscribe from.
   * @param listener The listener to unsubscribe.
   * @returns A reference to this Dart Frog daemon, so that calls can be
   * chained.
   */
  public off(
    type: DartFrogDaemonEventEmitterTypes,
    listener: (...args: any[]) => void
  ): DartFrogDaemon {
    this.daemonMessagesEventEmitter.off(type, listener);
    return this;
  }

  /**
   * Sends a request to the Dart Frog daemon.
   *
   * @param request The request to send to the Dart Frog daemon.
   * @throws {DartFrogDaemonNotInvokedError} If the Dart Frog daemon has not yet
   * been {@link invoke}d.
   * @throws {DartFrogDaemonReadyError} If the Dart Frog daemon is not yet
   * ready to accept requests.
   * @returns A promise that resolves to the response from the Dart Frog
   * daemon to the request.
   * @see {@link isReady} to check if the Dart Frog daemon is ready to accept
   * requests.
   */
  public send(request: DaemonRequest): Promise<DaemonResponse> {
    if (!this.process) {
      throw new DartFrogDaemonNotInvokedError();
    } else if (!this.isReady) {
      throw new DartFrogDaemonReadyError();
    }

    const responsePromise = new Promise<DaemonResponse>((resolve) => {
      const responseListener = (message: DaemonResponse) => {
        if (message.id === request.id && (message.result || message.error)) {
          this.off(DartFrogDaemonEventEmitterTypes.response, responseListener);
          resolve(message);
        }
      };
      this.on(
        DartFrogDaemonEventEmitterTypes.response,
        responseListener.bind(this)
      );
    });

    const encodedRequest = `${JSON.stringify([request])}\n`;
    this.process!.stdin.write(encodedRequest);
    this.daemonMessagesEventEmitter.emit(
      DartFrogDaemonEventEmitterTypes.request,
      request
    );

    return responsePromise;
  }
}
