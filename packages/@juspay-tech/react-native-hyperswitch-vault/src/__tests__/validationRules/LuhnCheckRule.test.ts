import { LuhnCheckRule } from '../../utils/validators/LuhnCheckRule';

describe('LuhnCheckRule', () => {
  it('should validate valid card numbers according to Luhn algorithm', () => {
    const rule = new LuhnCheckRule('Error message');
    expect(rule.validate('4111111111111111')).toBe(true);
    expect(rule.validate('5136333333333335')).toBe(true);
    expect(rule.validate('370000000000002')).toBe(true);
  });

  it('should invalidate invalid card numbers', () => {
    const rule = new LuhnCheckRule('Error message');
    expect(rule.validate('49927398715')).toBe(false);
    expect(rule.validate('1234567812345678')).toBe(false);
  });

  it('should handle non-numeric inputs', () => {
    const rule = new LuhnCheckRule('Error message');
    expect(rule.validate('invalid')).toBe(false);
    expect(rule.validate('123a')).toBe(false);
  });
});
