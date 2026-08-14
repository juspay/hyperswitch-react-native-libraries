import { ValidationRule } from './Validator';

/**
 * ABARoutingNumberRule
 *
 * Validates US ABA routing numbers.
 *
 * Criteria:
 * - Exactly 9 digits.
 * - Checksum $3(d_0+d_3+d_6) + 7(d_1+d_4+d_7) + (d_2+d_5+d_8)$ divisible by 10.
 */
export class ABARoutingNumberRule extends ValidationRule {
  /**
   * Creates a new ABA routing number validator.
   *
   * @param errorMessage - Message returned when validation fails.
   */
  constructor(errorMessage: string) {
    super(errorMessage);
  }

  /**
   * Checks whether `input` is a valid ABA routing number.
   *
   * @param input - String of digits to validate.
   * @returns `true` if valid, `false` otherwise.
   */
  validate(input: string): boolean {
    if (!input || !/^\d{9}$/.test(input)) {
      return false;
    }

    const digits = input.split('').map(Number);
    // Regex ensures length is exactly 9; non-null assertions satisfy noUncheckedIndexedAccess.
    const sum =
      3 * (digits[0]! + digits[3]! + digits[6]!) +
      7 * (digits[1]! + digits[4]! + digits[7]!) +
      1 * (digits[2]! + digits[5]! + digits[8]!);

    return sum % 10 === 0;
  }
}

export default ABARoutingNumberRule;
