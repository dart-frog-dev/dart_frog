/**
 * Defines the protocol used by the Dart Frog daemon "daemon" domain and custom
 * type guards to check if an object is a valid message.
 *
 * @see {@link https://dart-frog.dev/advanced/daemon#daemon-domain Dart Frog daemon domain}
 */

import {
  DaemonEvent,
  DaemonRequest,
  isDaemonEvent,
  isDaemonRequest,
} from "../protocol";

const domainName = "daemon";

const requestVersionMethodName = `${domainName}.requestVersion`;

export class RequestVersionDaemonRequest extends DaemonRequest {
  constructor(id: string) {
    super();
    this.id = id;
  }

  public readonly id: string;
  public readonly method: string = requestVersionMethodName;
  public readonly params: undefined;
}

export function isRequestVersionDaemonRequest(
  object: any
): object is RequestVersionDaemonRequest {
  return isDaemonRequest(object) && object.method === requestVersionMethodName;
}

const killMethodName = `${domainName}.kill`;

export class KillDaemonRequest extends DaemonRequest {
  constructor(id: string) {
    super();
    this.id = id;
  }

  public readonly id: string;
  public readonly method: string = killMethodName;
  public readonly params: undefined;
}

export function isKillDaemonRequest(object: any): object is KillDaemonRequest {
  return isDaemonRequest(object) && object.method === killMethodName;
}

const readyEventName = `${domainName}.ready`;

export interface ReadyDaemonEvent extends DaemonEvent {
  event: string;
  params: {
    version: string;
    processId: number;
  };
}

export function isReadyDaemonEvent(object: any): object is ReadyDaemonEvent {
  return (
    isDaemonEvent(object) &&
    object.event === readyEventName &&
    typeof object.params.version === "string" &&
    typeof object.params.processId === "number"
  );
}
