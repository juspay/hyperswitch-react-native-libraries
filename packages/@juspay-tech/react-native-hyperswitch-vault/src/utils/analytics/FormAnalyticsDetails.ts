import { generateUUID } from '../Utils';

/**
 * FormAnalyticsDetails
 *
 * Immutable form-scoped analytics context.
 * Identifies events related to a specific `HyperswitchVault` instance.
 */
class FormAnalyticsDetails {
  /** Form ID to correlate fields to a single Vault form. */
  readonly formId: string;
  readonly tnt: string;
  readonly env: string;

  /**
   * Creates a new form analytics details object.
   *
   * @param tenantId - Vault tenant identifier.
   * @param environment - Environment label (`sandbox`, `live`, `live-<region>`).
   */
  constructor(tenantId: string, environment: string) {
    this.formId = generateUUID();
    this.tnt = tenantId;
    this.env = environment;
  }
}
export default FormAnalyticsDetails;
