import { ValidationRule } from './Validator';

/**
 * PatternRule
 *
 * Validates that the input matches a provided regular expression pattern.
 */
export class PatternRule extends ValidationRule {
  private pattern: string;

  /**
   * Creates a regex-based validation rule.
   *
   * @param pattern - Regex pattern string to validate against.
   * @param errorMessage - Message returned when validation fails.
   */
  constructor(pattern: string, errorMessage: string) {
    super(errorMessage);
    this.pattern = pattern;
  }

  /**
   * Checks whether `input` matches the configured regex pattern.
   *
   * @param input - String to validate.
   * @returns `true` if valid, `false` otherwise.
   */
  validate(input: string): boolean {
    // Edge case: handle undefined or null as invalid
    if (!input) {
      return false;
    }

    const regex = new RegExp(this.pattern);
    return regex.test(input);
  }
}
