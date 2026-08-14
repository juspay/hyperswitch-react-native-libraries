import { ValidationRule } from './Validator';

/**
 * CardExpDateRule
 *
 * Validates card expiration dates in formats `mmyy` or `mmyyyy`.
 * Ensures month is 01–12 and the date is not in the past or beyond a 20-year horizon.
 */
export class CardExpDateRule extends ValidationRule {
  private dateFormat: 'mmyy' | 'mmyyyy';

  /**
   * Creates an expiration date validator.
   *
   * @param dateFormat - Date format: `'mmyy'` or `'mmyyyy'`.
   * @param errorMessage - Message returned when validation fails.
   */
  constructor(dateFormat: 'mmyy' | 'mmyyyy', errorMessage: string) {
    super(errorMessage);
    this.dateFormat = dateFormat;
  }

  /**
   * Checks whether `value` is a valid expiration date per configured format.
   *
   * @param value - Date string to validate.
   * @returns `true` if valid, `false` otherwise.
   */
  validate(value: string): boolean {
    if (!value) {
      return false;
    }

    const currentDate = new Date();
    const currentYear = currentDate.getFullYear();
    const currentMonth = currentDate.getMonth() + 1; // Months are zero-based
    const maxYear = currentYear + 20;

    let month: number;
    let year: number;

    if (this.dateFormat === 'mmyy') {
      if (!/^\d{4}$/.test(value)) return false;
      month = parseInt(value.slice(0, 2), 10);
      year = parseInt(`20${value.slice(2, 4)}`, 10);
    } else if (this.dateFormat === 'mmyyyy') {
      if (!/^\d{6}$/.test(value)) return false;
      month = parseInt(value.slice(0, 2), 10);
      year = parseInt(value.slice(2, 6), 10);
    } else {
      return false;
    }

    if (month < 1 || month > 12) return false;
    if (year < currentYear || year > maxYear) return false;
    if (year === currentYear && month < currentMonth) return false;

    return true;
  }
}
