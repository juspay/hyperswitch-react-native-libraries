import { LengthRule } from '../../utils/validators/LengthRule';

describe('LengthRule', () => {
  it('should validate strings within the length range', () => {
    const rule = new LengthRule(3, 10, 'Error message');
    expect(rule.validate('123')).toBe(true);
    expect(rule.validate('1234567890')).toBe(true);
  });

  it('should invalidate strings outside the length range', () => {
    const rule = new LengthRule(3, 10, 'Error message');
    expect(rule.validate('12')).toBe(false);
    expect(rule.validate('12345678901')).toBe(false);
  });

  it('should handle edge cases', () => {
    const rule = new LengthRule(3, 10, 'Error message');
    expect(rule.validate('')).toBe(false);
    expect(rule.validate(null as any)).toBe(false);
    expect(rule.validate(undefined as any)).toBe(false);
  });
});
