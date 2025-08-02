/**
 * Defines the protocol used by the Dart Frog daemon and custom
 * type guards to check if an object is a valid message.
 *
 * @see {@link https://github.com/dart-frog-dev/dart_frog/blob/main/packages/dart_frog_cli/lib/src/daemon/protocol.dart Dart Frog dart's protocol}
 */

export class DaemonMessage {
  /**
   * Decodes messages that follow the protocol.
   *
   * @param data The data to decode (usually from stdout of the Dart Frog
   * daemon and in JSON format).
   * @returns The decoded messages.
   */
  public static decode(data: Buffer): DaemonMessage[] {
    const stringData = data.toString();
    const messages = stringData.split("\n").filter((s) => s.trim().length > 0);
    const parsedMessages = messages.map((message) => JSON.parse(message));

    let daemonMessages: DaemonMessage[] = [];
    for (const parsedMessage of parsedMessages) {
      for (const message of parsedMessage) {
        daemonMessages.push(message as DaemonMessage);
      }
    }

    return daemonMessages;
  }
}

export abstract class DaemonRequest implements DaemonMessage {
  abstract method: string;
  abstract id: string;
  abstract params: any;
}

export function isDaemonRequest(object: any): object is DaemonRequest {
  return typeof object.id === "string" && typeof object.method === "string";
}

export interface DaemonResponse extends DaemonMessage {
  id: string;
  result: any;
  error: any;
}

export function isDaemonResponse(object: any): object is DaemonResponse {
  return typeof object.id === "string" && !("method" in object);
}

export interface DaemonEvent extends DaemonMessage {
  event: string;
  params: any;
}

export function isDaemonEvent(object: any): object is DaemonEvent {
  return typeof object.event === "string";
}
