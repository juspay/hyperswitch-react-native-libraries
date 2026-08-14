import { ValidationRule } from './Validator';

/**
 * Interface representing a date with day, month, and year components.
 */
interface HyperswitchDateInterface {
  day: number;
  month: number;
  year: number;
}
/** Class representing a date with day, month, and year components. */
export class HyperswitchDate implements HyperswitchDateInterface {
  day: number;
  month: number;
  year: number;

  /**
   * Creates a new HyperswitchDate instance.
   * @param date - The day of the month.
   * @param month - The month of the year.
   * @param year - The year.
   */
  public constructor(date: number, month: number, year: number) {
    this.day = date;
    this.month = month;
    this.year = year;
  }

  /**
   * Create `HyperswitchDate` from a string with a given format.
   *
   * @param dateString - Date string to parse.
   * @param format - One of `'ddmmyyyy'`, `'mmddyyyy'`, `'yyyymmdd'`.
   * @returns Parsed `HyperswitchDate` or `null` if parsing fails.
   */
  public static dateFromString(
    dateString: string,
    format: HyperswitchDateFormatType
  ): HyperswitchDate | null {
    if (dateString.length === 8) {
      var day = NaN;
      var month = NaN;
      var year = NaN;
      switch (format) {
        case 'mmddyyyy': {
          month = parseInt(dateString.slice(0, 2), NaN);
          day = parseInt(dateString.slice(2, 4), NaN);
          year = parseInt(dateString.slice(4, 8), NaN);
          break;
        }
        case 'ddmmyyyy': {
          day = parseInt(dateString.slice(0, 2), NaN);
          month = parseInt(dateString.slice(2, 4), NaN);
          year = parseInt(dateString.slice(4, 8), NaN);
          break;
        }
        case 'yyyymmdd': {
          year = parseInt(dateString.slice(0, 4), NaN);
          month = parseInt(dateString.slice(4, 6), NaN);
          day = parseInt(dateString.slice(6, 8), NaN);
          break;
        }
        default:
          console.error(`Wrong HyperswitchDateFormatType: ${format}`);
          return null;
      }
      if (!isNaN(day) && !isNaN(month) && !isNaN(year)) {
        return new HyperswitchDate(day, month, year);
      }
      return null;
    } else {
      return null;
    }
  }

  /** Compare if this date is less than or equal to another `HyperswitchDate`. */
  public lte(other: HyperswitchDate): boolean {
    if (this.year !== other.year) {
      return this.year < other.year;
    }
    if (this.month !== other.month) {
      return this.month < other.month;
    }
    return this.day <= other.day;
  }

  /** Compare if this date is greater than or equal to another `HyperswitchDate`. */
  public gte(other: HyperswitchDate): boolean {
    if (this.year !== other.year) {
      return this.year > other.year;
    }
    if (this.month !== other.month) {
      return this.month > other.month;
    }
    return this.day >= other.day;
  }

  /** Check if this date is between two other dates (inclusive). */
  public isBetween(start: HyperswitchDate, end: HyperswitchDate): boolean {
    return this.gte(start) && this.lte(end);
  }
}
/**
 * Supported date formats:
 * - `ddmmyyyy`: day, month, year
 * - `mmddyyyy`: month, day, year
 * - `yyyymmdd`: year, month, day
 */
export type HyperswitchDateFormatType = 'ddmmyyyy' | 'mmddyyyy' | 'yyyymmdd';

/**
 * DateRangeRule
 *
 * Validates that a date string falls within specified bounds.
 * Accepts optional start/end constraints and a required format.
 */
export class DateRangeRule extends ValidationRule {
  private dateFormat: HyperswitchDateFormatType;
  private startDate: HyperswitchDate | null = null;
  private endDate: HyperswitchDate | null = null;

  /**
   * Creates a date range validator.
   *
   * @param dateFormat - Format of input date string.
   * @param errorMessage - Message returned when validation fails.
   * @param start - Optional inclusive start bound.
   * @param end - Optional inclusive end bound.
   */
  public constructor(
    dateFormat: HyperswitchDateFormatType,
    errorMessage: string,
    start?: HyperswitchDate,
    end?: HyperswitchDate
  ) {
    super(errorMessage);
    this.dateFormat = dateFormat;
    this.startDate = start ?? null;
    this.endDate = end ?? null;
  }

  /**
   * Checks whether `value` parses and satisfies the configured range.
   *
   * @param value - Date string to validate.
   * @returns `true` if valid, `false` otherwise.
   */
  validate(value: string): boolean {
    if (!value) {
      return false;
    }
    const inputDate = HyperswitchDate.dateFromString(value, this.dateFormat);
    if (!inputDate) {
      return false;
    }
    // When startDate and endDate are set, validate that startDate <= inputDate <= endDate
    if (this.startDate && this.endDate) {
      return inputDate.isBetween(this.startDate, this.endDate);
    }

    // When only startDate is set, validate that startDate <= inputDate
    if (this.startDate) {
      return inputDate.gte(this.startDate);
    }

    // When only endDate is set, validate that inputDate <= endDate
    if (this.endDate) {
      return inputDate.lte(this.endDate);
    }
    // If no date constraints are set, the date is considered valid
    return true;
  }
}
