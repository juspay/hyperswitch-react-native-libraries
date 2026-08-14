import {
  maskInput,
  unmaskInput,
  getUnmaskedValue,
  PLACEHOLDERS,
  isValidCharacter,
} from '../../utils/masker/Masker';

describe('Masker', () => {
  describe('maskInput', () => {
    it('should mask input correctly with basic numeric pattern', () => {
      expect(maskInput('12345678', '##-##-##-##')).toBe('12-34-56-78');
    });

    it('should mask input with different placeholders', () => {
      expect(maskInput('abc123', '@@-###')).toBe('ab-123');
      expect(maskInput('ABC123', 'AA-###')).toBe('AB-123');
      expect(maskInput('aBc123', 'aa-###')).toBe('ac-123');
      expect(maskInput('aBc123', 'a*-###')).toBe('aB-123');
    });

    it('should handle dividers correctly', () => {
      expect(maskInput('12345678', '##/##/##/##', '/')).toBe('12/34/56/78');
      expect(maskInput('12345678', '##-##-##-##', '-')).toBe('12-34-56-78');
    });

    it('should handle prefixes correctly', () => {
      expect(maskInput('12345678', '##-##-##-##', '-', '+1 ')).toBe(
        '+1 12-34-56-78'
      );
    });

    it('should handle empty input', () => {
      expect(maskInput('', '##-##-##-##')).toBe('');
    });

    it('should handle invalid characters', () => {
      expect(maskInput('123abc456', '##-##-##-##')).toBe('12-34-56');
    });

    it('should handle incomplete masks', () => {
      expect(maskInput('12345678', '##-##')).toBe('12-34');
    });

    it('should handle masks longer than input', () => {
      expect(maskInput('1234', '##-##-##-##')).toBe('12-34');
    });

    it('should handle special characters in the mask', () => {
      expect(maskInput('1234', '##.##')).toBe('12.34');
    });

    it('should handle consecutive placeholders', () => {
      expect(maskInput('123456', '####-##')).toBe('1234-56');
    });
  });

  describe('unmaskInput', () => {
    it('should unmask input correctly', () => {
      expect(unmaskInput('12-34-56-78', '##-##-##-##')).toBe('12345678');
      expect(unmaskInput('ab-123', '@@-###')).toBe('ab123');
      expect(unmaskInput('AB-123', 'AA-###')).toBe('AB123');
      expect(unmaskInput('bc-123', 'aa-###')).toBe('bc123');
      expect(unmaskInput('aB-123', '*a-###')).toBe('aB123');
    });

    it('should handle empty input', () => {
      expect(unmaskInput('', '##-##-##-##')).toBe('');
    });

    it('should handle input with no separators', () => {
      expect(unmaskInput('12345678', '########')).toBe('12345678');
    });
  });

  describe('getUnmaskedValue', () => {
    it('should return the raw unmasked value', () => {
      expect(getUnmaskedValue('12-34-56-78', '##-##-##-##')).toBe('12345678');
    });

    it('should re-mask the value with the divider if provided', () => {
      expect(getUnmaskedValue('12/34/56/78', '##-##-##-##', '-')).toBe(
        '12-34-56-78'
      );
    });
  });

  describe('isValidCharacter', () => {
    it.each(PLACEHOLDERS)(
      'should validate character correctly for %s',
      (placeholder) => {
        switch (placeholder) {
          case '#':
            expect(isValidCharacter('1', placeholder)).toBe(true);
            expect(isValidCharacter('a', placeholder)).toBe(false);
            break;
          case '@':
            expect(isValidCharacter('a', placeholder)).toBe(true);
            expect(isValidCharacter('1', placeholder)).toBe(false);
            break;
          case 'a':
            expect(isValidCharacter('a', placeholder)).toBe(true);
            expect(isValidCharacter('A', placeholder)).toBe(false);
            break;
          case 'A':
            expect(isValidCharacter('A', placeholder)).toBe(true);
            expect(isValidCharacter('a', placeholder)).toBe(false);
            break;
          case '*':
            expect(isValidCharacter('a', placeholder)).toBe(true);
            expect(isValidCharacter('A', placeholder)).toBe(true);
            expect(isValidCharacter('1', placeholder)).toBe(true);
            expect(isValidCharacter('!', placeholder)).toBe(false);
            break;
        }
      }
    );
  });
});
