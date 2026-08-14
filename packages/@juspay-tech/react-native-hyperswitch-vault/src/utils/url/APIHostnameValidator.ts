// APIHostnameValidator.ts

import HyperswitchVaultLogger, {
  HyperswitchLogLevel,
  HyperswitchLogSeverity,
} from '../logger/HyperswitchVaultLogger';

/**
 * APIHostnameValidator
 *
 * Validates custom CNAME hostnames for `HyperswitchVault` against a configuration endpoint.
 * Ensures that submissions only proceed with verified hosts.
 */
class APIHostnameValidator {
  static readonly Constants = {
    validStatuses: [200, 300],
  };

  static readonly hostValidatorBaseURL = 'https://js.hyperswitch-vault.com';

  /**
   * Validates a custom hostname and returns `true` when resolvable.
   * Logs errors via the SDK logger when invalid.
   *
   * @param hostname - Candidate CNAME hostname provided by the integrator.
   * @param tenantId - Vault tenant ID used to construct validation URL.
   * @returns `true` if validation succeeds, `false` otherwise.
   */
  static async validateCustomHostname(
    hostname: string,
    tenantId: string
  ): Promise<boolean> {
    if (!hostname) {
      return false;
    }

    const normalizedHostname = this.normalizeHostname(hostname);
    if (!normalizedHostname) {
      this.logCnameError(
        'Hostname is invalid (empty) and will be ignored. Default Vault URL will be used.'
      );
      return false;
    }
    try {
      const url = await this.buildHostValidationURLstring(
        normalizedHostname,
        tenantId
      );
      if (!url) {
        this.logCnameError(
          `Error: Cannot build validation URL with tenantId: "${tenantId}", hostname: "${hostname}"`
        );
        return false;
      }
      const response = await fetch(url);
      if (!response.ok) {
        const message =
          response.status === 403
            ? `A specified host: "${hostname}" was not correct. Activate this CNAME for Hyperswitch Vault before using it.`
            : `Error: Cannot resolve hostname "${hostname}". Status code: ${response.status}`;
        this.logCnameError(message);
        return false;
      }

      const responseText = await response.text();
      return responseText.includes(normalizedHostname);
    } catch (error) {
      this.logCnameError(
        `Error: Cannot resolve hostname "${normalizedHostname}". Error: ${error}`
      );
      return false;
    }
  }

  private static logCnameError(message: string) {
    HyperswitchVaultLogger.getInstance().log({
      logLevel: HyperswitchLogLevel.WARNING,
      text: message,
      severity: HyperswitchLogSeverity.ERROR,
    });
  }

  /**
   * Constructs the validation URL used to verify the hostname.
   */
  private static async buildHostValidationURLstring(
    normalizedHostname: string,
    tenantId: string
  ): Promise<string | null> {
    const hostPath = `collect-configs/${normalizedHostname}__${tenantId}.txt`;
    const url = new URL(hostPath, this.hostValidatorBaseURL);
    return url.toString();
  }

  /**
   * Normalizes input into a hostname string.
   * Accepts raw hostnames and full URLs; returns `null` on parse failure.
   */
  static normalizeHostname(url: string): string | null {
    if (!/^https?:\/\//i.test(url)) {
      url = `https://${url}`;
    }
    try {
      const parsedUrl = new URL(url);
      // Return the hostname directly (ignores query params, paths, etc.)
      return parsedUrl.hostname;
    } catch (error) {
      return null;
    }
  }
}

export default APIHostnameValidator;
