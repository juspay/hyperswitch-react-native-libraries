import { ValidationRule } from './Validator';

/**
 * NotEmptyRule
 *
 * Validates that input is a non-empty string after trimming whitespace.
 */
export class NotEmptyRule extends ValidationRule {
  /**
   * Returns `true` when `input.trim().length > 0`.
   *
   * @param input - String to check for emptiness.
   * @returns `true` if non-empty, `false` otherwise.
   */
  validate(input: string): boolean {
    if (input == null) {
      return false;
    }
    return input.trim().length > 0;
  }
}
