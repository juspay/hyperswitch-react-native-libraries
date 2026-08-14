import { PatternRule } from '../../utils/validators/PatternRule';

describe('PatternRule', () => {
  it('should validate strings matching the pattern', () => {
    const rule = new PatternRule('^[a-zA-Z]+$', 'Error message');
    expect(rule.validate('valid')).toBe(true);
    expect(rule.validate('anotherValid')).toBe(true);
  });

  it('should invalidate strings not matching the pattern', () => {
    const rule = new PatternRule('^[a-zA-Z]+$', 'Error message');
    expect(rule.validate('123')).toBe(false);
    expect(rule.validate('invalid1')).toBe(false);
  });

  it('should handle edge cases', () => {
    const rule = new PatternRule('^[a-zA-Z]+$', 'Error message');
    expect(rule.validate('')).toBe(false);
    expect(rule.validate(null as any)).toBe(false);
    expect(rule.validate(undefined as any)).toBe(false);
  });
});
