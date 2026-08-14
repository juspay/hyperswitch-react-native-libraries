import { ValidationRule } from './Validator';
import HyperswitchVault from '../../vault/HyperswitchVault';

/**
 * MatchFieldRule
 *
 * Secure cross-field equality validator.
 * Compares current input against another field's value via a comparator without exposing raw data.
 */
export class MatchFieldRule extends ValidationRule {
  private readonly id: string;
  private readonly targetFieldName: string;

  /**
   * Creates a cross-field match validator.
   *
   * @param id - Form identifier shared by the compared fields.
   * @param targetFieldName - Field name to compare against.
   * @param errorMessage - Message when values do not match.
   */
  constructor(id: string, targetFieldName: string, errorMessage: string) {
    super(errorMessage);
    this.id = id;
    this.targetFieldName = targetFieldName;
  }

  /**
   * Checks whether `input` equals the target field value.
   *
   * @param input - String to compare.
   * @returns `true` if equal, `false` otherwise.
   */
  validate(input: string): boolean {
    if (!input) return false;
    // Get a comparator function that doesn't expose the raw value
    const comparator = HyperswitchVault.getFieldComparator(
      this.id,
      this.targetFieldName
    );
    return comparator(input);
  }
}

export default MatchFieldRule;
