import { ValidationRule } from './Validator';

/**
 * LuhnCheckRule
 *
 * Validates input using the Luhn checksum algorithm (mod 10).
 * Commonly used for payment card numbers.
 */
export class LuhnCheckRule extends ValidationRule {
  /**
   * Checks whether `input` passes the Luhn algorithm.
   * Non-numeric inputs are rejected.
   *
   * @param input - String to validate (spaces/dashes tolerated).
   * @returns `true` if valid, `false` otherwise.
   */
  validate(input: string): boolean {
    const num = input.replace(/\s+|-/g, ''); // Remove spaces and dashes

    if (!/^\d+$/.test(num)) {
      return false; // Reject non-numeric inputs
    }

    return luhnCheck(num); // Validate using Luhn algorithm
  }
}

/** Helper function for Luhn validation. */
const luhnCheck = (num: string): boolean => {
  var digit, digits, i, len, odd, sum;
  odd = true;
  sum = 0;
  digits = (num + '').split('').reverse();
  for (i = 0, len = digits.length; i < len; i++) {
    digit = digits[i] ?? '0';
    digit = parseInt(digit, 10);
    if ((odd = !odd)) {
      digit *= 2;
    }
    if (digit > 9) {
      digit -= 9;
    }
    sum += digit;
  }
  return sum % 10 === 0;
};
