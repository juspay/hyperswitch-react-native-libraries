import { ValidationRule } from './Validator';

/**
 * LengthRule
 *
 * Validates that input length is within `[min, max]` bounds.
 */
export class LengthRule extends ValidationRule {
  private min: number;
  private max: number;

  /**
   * Creates a bounded length validator.
   *
   * @param min - Minimum length (default: `0`).
   * @param max - Maximum length (default: `Infinity`).
   * @param errorMessage - Message returned when validation fails.
   */
  constructor(min: number = 0, max: number = Infinity, errorMessage: string) {
    super(errorMessage);
    this.min = min;
    this.max = max;
  }

  /**
   * Checks whether `input.length` satisfies `min <= length <= max`.
   *
   * @param input - String to validate.
   * @returns `true` if valid, `false` otherwise.
   */
  validate(input: string): boolean {
    // Edge case: handle undefined or null as invalid
    if (!input) {
      return false;
    }

    return input.length >= this.min && input.length <= this.max;
  }
}
