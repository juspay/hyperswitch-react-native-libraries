/**
 * Log level enum.
 */
export enum HyperswitchLogSeverity {
  WARNING = `⚠️`,
  ERROR = `❌`,
}

/**
 * Severity level enum.
 */
export enum HyperswitchLogLevel {
  /// Log *all* events including errors and warnings.
  INFO = 'info',
  // Log *only* events indicating warnings and errors.
  WARNING = 'warning',
  /// Log *no* events.
  NONE = 'none',
}

/**
 * Log event interface.
 */
export interface HyperswitchLogEvent {
  logLevel: HyperswitchLogLevel;
  text: string;
  severity: HyperswitchLogSeverity;
}

/**
 * HyperswitchVaultLogger
 *
 * Singleton logger for the SDK.
 * Provides methods to enable/disable logging and log events, requests, and responses.
 * Logging is automatically prevented from enabling in production builds.
 */
class HyperswitchVaultLogger {
  private static instance: HyperswitchVaultLogger;
  private isEnabled: boolean = false;

  /**
   * Private constructor for singleton pattern.
   */
  private constructor() {}

  /**
   * Returns the singleton logger instance.
   */
  public static getInstance(): HyperswitchVaultLogger {
    if (!HyperswitchVaultLogger.instance) {
      HyperswitchVaultLogger.instance = new HyperswitchVaultLogger();
    }
    return HyperswitchVaultLogger.instance;
  }

  /**
   * Enables logging (no-op in production).
   */
  public enable(): void {
    // Prevent enabling logs in production
    if (process.env.NODE_ENV === 'production') {
      return;
    }
    this.isEnabled = true;
  }

  /**
   * Disables logging.
   */
  public disable(): void {
    this.isEnabled = false;
  }

  /**
   * Logs an event.
   *
   * @param event - Event with level, severity, and text.
   */
  log(event: HyperswitchLogEvent): void {
    const { logLevel, text, severity } = event;
    if (!this.isEnabled || logLevel === HyperswitchLogLevel.NONE) {
      return;
    }

    const logMessage = `${severity} HyperswitchVaultSDK: ${text}`;
    if (severity === HyperswitchLogSeverity.ERROR) {
      console.error(logMessage);
    } else {
      console.log(logMessage);
    }
  }

  logRequest(
    url: string,
    headers: Record<string, any>,
    payload: Record<string, any>
  ) {
    // Safe logging; payload should not contain raw sensitive values.
    if (!this.isEnabled) {
      return;
    }
    console.log(`⬆️ Send HyperswitchVaultSDK request url: ${url}`);
    const headersString = JSON.stringify(headers, null, 2);
    console.log(
      `⬆️ Send HyperswitchVaultSDK request headers: ${headersString}`
    );
    const payloadString = JSON.stringify(payload, null, 2);
    console.log(
      `⬆️ Send HyperswitchVaultSDK request payload: ${payloadString}`
    );
    console.log('------------------------------------');
  }

  /**
   * Logs a `fetch` response including status, headers and JSON body.
   *
   * @param response - Fetch Response object.
   */
  async logResponse(response: any): Promise<void> {
    if (!this.isEnabled) {
      return;
    }
    this.logBaseResponseData(response);
    const statusString = this.baseStatusString(response.ok);
    const headersString = JSON.stringify(response.headers, null, 2);
    console.log(`${statusString}  response headers: ${headersString}`);
    try {
      const responseBody = await response.clone().json();
      const bodyString = JSON.stringify(responseBody, null, 2);
      console.log(`${statusString}  response body: ${bodyString}`);
    } catch (error) {
      console.error(
        'HyperswitchVaultLogger: ❗ Error parsing response body. Body is empty or wrong format(expecting JSON). Check your <vaultId> and backend response object:',
        error
      );
    }
    console.log('------------------------------------');
  }

  /**
   * Logs tokenization response with the resulting alias map.
   */
  logTokenizationResponse(response: any, result: Record<string, string>) {
    if (!this.isEnabled) {
      return;
    }
    this.logBaseResponseData(response);
    const statusString = this.baseStatusString(response.ok);
    console.log(`${statusString}  response body:`);
    console.log(result);
  }

  /**
   * Logs base response data (URL and status) with validation.
   */
  private logBaseResponseData(response: any) {
    if (!(response instanceof Response)) {
      this.log({
        severity: HyperswitchLogSeverity.ERROR,
        text: `Response is not valid. Response object: ${response}`,
        logLevel: HyperswitchLogLevel.WARNING,
      });
      return;
    }
    const statusString = this.baseStatusString(response.ok);
    console.log(`${statusString} request url: ${response.url}`);
    console.log(`${statusString}  response code: ${response.status}`);
  }

  /**
   * Returns a status prefix for success/failure.
   */
  private baseStatusString(ok: Boolean): string {
    return ok
      ? '✅ Success ⬇️ HyperswitchVaultSDK'
      : '❗ Failed ⬇️ HyperswitchVaultSDK';
  }

  logRequestError(
    error: Error,
    url: string,
    headers: Record<string, any> = {},
    payload: Record<string, any> = {}
  ) {
    // Safe logging; payload should not contain raw sensitive values.
    if (!this.isEnabled) {
      return;
    }
    console.error(`❗ Failed ⬆️ HyperswitchVaultSDK request url: ${url}`);
    console.error(
      `❗ Failed ⬆️ HyperswitchVaultSDK request headers: ${headers}`
    );
    console.error(
      `❗ Failed ⬆️ HyperswitchVaultSDK request payload: ${payload}`
    );
    console.error(`❗ Failed ⬆️ HyperswitchVaultSDK error: ${error}`);
    console.error('------------------------------------');
  }
}

export default HyperswitchVaultLogger;
