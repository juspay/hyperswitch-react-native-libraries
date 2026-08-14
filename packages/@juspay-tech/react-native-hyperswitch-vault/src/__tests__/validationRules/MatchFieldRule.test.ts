import { MatchFieldRule } from '../../utils/validators/MatchFieldRule';
import HyperswitchVault from '../../vault/HyperswitchVault';

/**
 * Minimal mock registration using real HyperswitchVault to ensure integration path works.
 */
describe('MatchFieldRule', () => {
  const id = 'match-field-form';

  beforeEach(() => {
    HyperswitchVault.reset();
    HyperswitchVault.registerField(
      id,
      'primary',
      () => 'secret-value',
      () => [],
      undefined,
      'text',
      []
    );
  });

  it('validates when input matches other field value', () => {
    const rule = new MatchFieldRule(id, 'primary', 'Values mismatch');
    expect(rule.validate('secret-value')).toBe(true);
  });

  it('invalidates when input differs', () => {
    const rule = new MatchFieldRule(id, 'primary', 'Values mismatch');
    expect(rule.validate('different')).toBe(false);
  });

  it('invalidates when other field missing', () => {
    const rule = new MatchFieldRule(id, 'missing', 'Values mismatch');
    expect(rule.validate('anything')).toBe(false);
  });

  it('invalidates empty input', () => {
    const rule = new MatchFieldRule(id, 'primary', 'Values mismatch');
    expect(rule.validate('')).toBe(false);
  });
});
