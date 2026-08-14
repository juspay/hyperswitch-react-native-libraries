import { resolveEffectiveMaxLength } from '../../components/HyperswitchTextInputBase';

describe('resolveEffectiveMaxLength', () => {
  it('returns provided maxLength when mask is not set', () => {
    expect(resolveEffectiveMaxLength(10)).toBe(10);
  });

  it('returns mask length when maxLength is not set', () => {
    expect(resolveEffectiveMaxLength(undefined, '##-##-##')).toBe(8);
  });

  it('caps maxLength to mask length when both are set', () => {
    expect(resolveEffectiveMaxLength(12, '#### ####')).toBe(9);
  });

  it('keeps smaller maxLength when it is below mask length', () => {
    expect(resolveEffectiveMaxLength(4, '#### ####')).toBe(4);
  });
});
