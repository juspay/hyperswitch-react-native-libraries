import { ABARoutingNumberRule } from '../../utils/validators/ABARoutingNumberRule';

describe('ABARoutingNumberRule', () => {
  const msg = 'is not a valid ABA routing number';

  it('Valid ABA Routing Number', () => {
    const rule = new ABARoutingNumberRule(msg);
    expect(rule.validate('100000175')).toBe(true);
  });

  it('Invalid ABA Routing Number (checksum)', () => {
    const rule = new ABARoutingNumberRule(msg);
    expect(rule.validate('123456789')).toBe(false);
  });

  it('Invalid ABA Routing Number (format)', () => {
    const rule = new ABARoutingNumberRule(msg);
    expect(rule.validate('12345678')).toBe(false);
    expect(rule.validate('1234567890')).toBe(false);
    expect(rule.validate('abcdefghi')).toBe(false);
  });

  it('Empty ABA Routing Number', () => {
    const rule = new ABARoutingNumberRule(msg);
    expect(rule.validate('')).toBe(false);
  });
});
