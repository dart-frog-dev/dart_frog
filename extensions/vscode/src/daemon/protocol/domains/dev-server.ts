/**
 * Defines the protocol used by the Dart Frog daemon "dev-server" domain and
 * custom type guards to check if an object is a valid message.
 *
 * @see {@link https://dart-frog.dev/advanced/daemon#dev_server-domain Dart Frog dev server domain}
 */

import {
  DaemonEvent,
  DaemonRequest,
  isDaemonEvent,
  isDaemonRequest,
} from "../protocol";

const domainName = "dev_server";

const startMethodName = `${domainName}.start`;

export class StartDaemonRequest extends DaemonRequest {
  constructor(
    id: string,
    workingDirectory: string,
    port: number,
    dartVmServicePort: number
  ) {
    super();
    this.id = id;
    this.params = {
      workingDirectory: workingDirectory,
      port: port,
      dartVmServicePort: dartVmServicePort,
    };
  }

  public readonly method: string = startMethodName;
  public readonly id: string;
  public readonly params: {
    workingDirectory: string;
    port: number;
    dartVmServicePort: number;
  };
}

export function isStartDaemonRequest(
  object: any
): object is StartDaemonRequest {
  return (
    isDaemonRequest(object) &&
    object.method === startMethodName &&
    typeof object.params.workingDirectory === "string" &&
    typeof object.params.port === "number" &&
    typeof object.params.dartVmServicePort === "number"
  );
}

const reloadMethodName = `${domainName}.reload`;

export class ReloadDaemonRequest extends DaemonRequest {
  constructor(id: string, applicationId: string) {
    super();
    this.id = id;
    this.params = {
      applicationId: applicationId,
    };
  }

  public readonly method: string = reloadMethodName;
  public readonly id: string;
  public readonly params: { applicationId: string };
}

export function isReloadDaemonRequest(
  object: any
): object is ReloadDaemonRequest {
  return (
    isDaemonRequest(object) &&
    object.method === reloadMethodName &&
    typeof object.params.applicationId === "string"
  );
}

const stopMethodName = `${domainName}.stop`;

export class StopDaemonRequest extends DaemonRequest {
  constructor(id: string, applicationId: string) {
    super();
    this.id = id;
    this.params = {
      applicationId: applicationId,
    };
  }

  public readonly method: string = stopMethodName;
  public readonly id: string;
  public readonly params: { applicationId: string };
}

export function isStopDaemonRequest(object: any): object is StopDaemonRequest {
  return (
    isDaemonRequest(object) &&
    object.method === stopMethodName &&
    typeof object.params.applicationId === "string"
  );
}

const applicationStartingEventName = `${domainName}.applicationStarting`;

export interface ApplicationStartingDaemonEvent extends DaemonEvent {
  params: {
    applicationId: string;
    requestId: string;
  };
}

export function isApplicationStartingDaemonEvent(
  object: any
): object is ApplicationStartingDaemonEvent {
  return (
    isDaemonEvent(object) &&
    object.event === applicationStartingEventName &&
    typeof object.params.applicationId === "string" &&
    typeof object.params.requestId === "string"
  );
}

const applicationExitEventName = `${domainName}.applicationExit`;

export interface ApplicationExitDaemonEvent extends DaemonEvent {
  params: { applicationId: string; requestId: string; exitCode: number };
}

export function isApplicationExitDaemonEvent(
  object: any
): object is ApplicationExitDaemonEvent {
  return (
    isDaemonEvent(object) &&
    object.event === applicationExitEventName &&
    typeof object.params.applicationId === "string" &&
    typeof object.params.requestId === "string" &&
    typeof object.params.exitCode === "number"
  );
}

const loggerInfoEventName = `${domainName}.loggerInfo`;

export interface LoggerInfoDaemonEvent extends DaemonEvent {
  params: {
    applicationId: string;
    requestId: string;
    workingDirectory: string;
    message: string;
  };
}

export function isLoggerInfoDaemonEvent(
  object: any
): object is LoggerInfoDaemonEvent {
  return (
    isDaemonEvent(object) &&
    object.event === loggerInfoEventName &&
    typeof object.params.applicationId === "string" &&
    typeof object.params.requestId === "string" &&
    typeof object.params.workingDirectory === "string" &&
    typeof object.params.message === "string"
  );
}

const loggerDetailEventName = `${domainName}.loggerDetail`;

export interface LoggerDetailDaemonEvent extends DaemonEvent {
  params: {
    applicationId: string;
    requestId: string;
    workingDirectory: string;
    message: string;
  };
}

export function isLoggerDetailDaemonEvent(
  object: any
): object is LoggerDetailDaemonEvent {
  return (
    isDaemonEvent(object) &&
    object.event === loggerDetailEventName &&
    typeof object.params.applicationId === "string" &&
    typeof object.params.requestId === "string" &&
    typeof object.params.workingDirectory === "string" &&
    typeof object.params.message === "string"
  );
}

const progessStartEventName = `${domainName}.progressStart`;

export interface ProgressStartDaemonEvent extends DaemonEvent {
  params: {
    applicationId: string;
    requestId: string;
    workingDirectory: string;
    progressMessage: string;
    progressId: string;
  };
}

export function isProgressStartDaemonEvent(
  object: any
): object is ProgressStartDaemonEvent {
  return (
    isDaemonEvent(object) &&
    object.event === progessStartEventName &&
    typeof object.params.applicationId === "string" &&
    typeof object.params.requestId === "string" &&
    typeof object.params.workingDirectory === "string" &&
    typeof object.params.progressMessage === "string" &&
    typeof object.params.progressId === "string"
  );
}

const progressCompleteEventName = `${domainName}.progressComplete`;

export interface ProgressCompleteDaemonEvent extends DaemonEvent {
  params: {
    applicationId: string;
    requestId: string;
    workingDirectory: string;
    progressMessage: string;
    progressId: string;
  };
}

export function isProgressCompleteDaemonEvent(
  object: any
): object is ProgressCompleteDaemonEvent {
  return (
    isDaemonEvent(object) &&
    object.event === progressCompleteEventName &&
    typeof object.params.applicationId === "string" &&
    typeof object.params.requestId === "string" &&
    typeof object.params.workingDirectory === "string" &&
    typeof object.params.progressMessage === "string" &&
    typeof object.params.progressId === "string"
  );
}
