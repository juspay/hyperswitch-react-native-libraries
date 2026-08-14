import { LengthMatchRule } from '../../utils/validators/LengthMatchRule';

describe('LengthMatchRule', () => {
  it('should validate strings with the exact specified length', () => {
    const rule = new LengthMatchRule(5, 'Error message');
    expect(rule.validate('12345')).toBe(true);
  });

  it('should invalidate strings with a different length', () => {
    const rule = new LengthMatchRule(5, 'Error message');
    expect(rule.validate('1234')).toBe(false);
    expect(rule.validate('123456')).toBe(false);
  });

  it('should handle edge cases', () => {
    const rule = new LengthMatchRule(5, 'Error message');
    expect(rule.validate('')).toBe(false);
    expect(rule.validate(null as any)).toBe(false);
    expect(rule.validate(undefined as any)).toBe(false);
  });
});
