import { NotEmptyRule } from '../../utils/validators/NotEmptyRule';

describe('NotEmptyRule', () => {
  it('should validate non-empty strings', () => {
    const rule = new NotEmptyRule('Error message');
    expect(rule.validate('valid')).toBe(true);
    expect(rule.validate('  valid  ')).toBe(true);
  });

  it('should invalidate empty strings, null, and undefined', () => {
    const rule = new NotEmptyRule('Error message');
    expect(rule.validate('')).toBe(false);
    expect(rule.validate('   ')).toBe(false);
    expect(rule.validate(null as any)).toBe(false);
    expect(rule.validate(undefined as any)).toBe(false);
  });
});
