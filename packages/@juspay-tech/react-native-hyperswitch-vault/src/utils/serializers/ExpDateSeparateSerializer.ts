import HyperswitchVaultLogger, {
  HyperswitchLogSeverity,
  HyperswitchLogLevel,
} from '../logger/HyperswitchVaultLogger';

// Define an interface for serializers
export interface HyperswitchSerializer {
  serialize(value: string): string | Record<string, string>;
}
/**
 * ExpDateSeparateSerializer
 *
 * Splits card expiration date strings into separate month and year fields.
 * Supports `mmyy` and `mmyyyy` formats.
 */
class ExpDateSeparateSerializer implements HyperswitchSerializer {
  private monthFieldName: string;
  private yearFieldName: string;
  /**
   * Creates a serializer that outputs `{ [monthFieldName]: MM, [yearFieldName]: YY|YYYY }`.
   *
   * @param monthFieldName - Output key for month.
   * @param yearFieldName - Output key for year.
   */
  public constructor(monthFieldName: string, yearFieldName: string) {
    this.monthFieldName = monthFieldName;
    this.yearFieldName = yearFieldName;
  }

  /**
   * Serializes `value` into `{ monthFieldName: MM, yearFieldName: YY|YYYY }`.
   * Returns empty strings for invalid formats.
   *
   * @param value - Expiration string in `mmyy` or `mmyyyy`.
   * @returns Record with month/year fields or empty values on error.
   */
  serialize(value: string): string | Record<string, string> {
    let month: string, year: string;
    // Use the same logic as in CardExpDateRule to extract month and year
    if (/^\d{4}$/.test(value)) {
      // mmyy format
      month = value.slice(0, 2);
      year = value.slice(2, 4);
    } else if (/^\d{6}$/.test(value)) {
      // mmyyyy format
      month = value.slice(0, 2);
      year = value.slice(2, 6);
    } else {
      HyperswitchVaultLogger.getInstance().log({
        logLevel: HyperswitchLogLevel.WARNING,
        text: `Invalid expiration date format: ${value}. Can not separate month and year.`,
        severity: HyperswitchLogSeverity.ERROR,
      });
      month = '';
      year = '';
    }
    return {
      [this.monthFieldName]: month,
      [this.yearFieldName]: year,
    };
  }
}

export default ExpDateSeparateSerializer;
