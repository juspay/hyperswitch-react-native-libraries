import { ValidationRule } from './Validator';

/**
 * LengthMatchRule
 *
 * Validates that input has exactly the specified length.
 */
export class LengthMatchRule extends ValidationRule {
  private length: number;

  /**
   * Creates an exact-length validator.
   *
   * @param length - Exact length required.
   * @param errorMessage - Message returned when validation fails.
   */
  constructor(length: number, errorMessage: string) {
    super(errorMessage);
    this.length = length;
  }

  /**
   * Checks whether `input.length === length`.
   *
   * @param input - String to validate.
   * @returns `true` if valid, `false` otherwise.
   */
  validate(input: string): boolean {
    // Edge case: handle undefined or null as invalid
    if (!input) {
      return false;
    }

    return input.length === this.length;
  }
}
