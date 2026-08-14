import { ValidationRule } from './Validator';
import { LuhnCheckRule } from './LuhnCheckRule';
import { PaymentCardBrandsManager } from '../paymentCards/PaymentCardBrandsManager';
import { CheckSumAlgorithmType } from '../paymentCards/PaymentCardBrand';

/**
 * PaymentCardRule
 *
 * Validates payment card numbers using detected brand heuristics and checksum.
 * Behavior:
 * - Strips spaces/dashes, requires numeric input.
 * - Detects brand, validates allowed lengths and checksum algorithm (e.g., Luhn).
 * - Optional fallback validation when brand is unknown.
 */
export class PaymentCardRule extends ValidationRule {
  private validateUnknownCardBrand: boolean;

  /**
   * Creates a payment card validator.
   *
   * @param errorMessage - Message returned when validation fails.
   * @param validateUnknownCardBrand - If `true`, applies fallback brand rules when detection fails.
   */
  constructor(errorMessage: string, validateUnknownCardBrand = false) {
    super(errorMessage);
    this.validateUnknownCardBrand = validateUnknownCardBrand;
  }

  /**
   * Checks whether `input` is a valid card number per brand rules.
   *
   * @param input - Card number string to validate.
   * @returns `true` if valid, `false` otherwise.
   */
  validate(input: string): boolean {
    // Remove spaces & dashes
    const cardNumber = input.replace(/\s+|-/g, '');

    // Must be numeric
    if (!/^\d+$/.test(cardNumber)) {
      return false;
    }

    // Detect known brand
    const manager = PaymentCardBrandsManager.getInstance();
    let brand = manager.detectBrand(cardNumber);

    if (brand) {
      // ### Known brand ###
      // 1) Check length
      if (!brand.cardNumberLengths.includes(cardNumber.length)) {
        return false;
      }
      // 2) If brand uses Luhn, check it
      if (
        brand.checkSumAlgorithm === CheckSumAlgorithmType.LUHN &&
        !LuhnCheckRule.prototype.validate(cardNumber)
      ) {
        return false;
      }
      return true; // passed
    } else if (!brand && this.validateUnknownCardBrand) {
      // ### Unknown brand case ###
      const unknownBrand = manager.getUnknownBrand();
      if (!unknownBrand) {
        // If there's no fallback brand defined, fail immediately
        return false;
      }
      // Check length
      if (!unknownBrand.cardNumberLengths.includes(cardNumber.length)) {
        return false;
      }
      // Check Luhn if needed
      if (
        unknownBrand.checkSumAlgorithm === CheckSumAlgorithmType.LUHN &&
        !LuhnCheckRule.prototype.validate(cardNumber)
      ) {
        return false;
      }
      return true;
    }

    // If brand is unknown and we do NOT validate unknown => fail
    return false;
  }
}
