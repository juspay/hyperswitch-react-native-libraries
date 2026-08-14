import {
  DateRangeRule,
  HyperswitchDate,
} from '../../utils/validators/DateRangeRule';
import type { HyperswitchDateFormatType } from '../../utils/validators/DateRangeRule';

describe('HyperswitchDate', () => {
  describe('dateFromString', () => {
    it('parses mmddyyyy format correctly', () => {
      const date = HyperswitchDate.dateFromString('12312023', 'mmddyyyy');
      expect(date).not.toBeNull();
      expect(date?.month).toBe(12);
      expect(date?.day).toBe(31);
      expect(date?.year).toBe(2023);
    });

    it('parses ddmmyyyy format correctly', () => {
      const date = HyperswitchDate.dateFromString('31122023', 'ddmmyyyy');
      expect(date).not.toBeNull();
      expect(date?.day).toBe(31);
      expect(date?.month).toBe(12);
      expect(date?.year).toBe(2023);
    });

    it('parses yyyymmdd format correctly', () => {
      const date = HyperswitchDate.dateFromString('20231231', 'yyyymmdd');
      expect(date).not.toBeNull();
      expect(date?.year).toBe(2023);
      expect(date?.month).toBe(12);
      expect(date?.day).toBe(31);
    });

    it('returns null for invalid format', () => {
      const date = HyperswitchDate.dateFromString(
        '20231231',
        'invalid' as HyperswitchDateFormatType
      );
      expect(date).toBeNull();
    });

    it('returns null for string of wrong length', () => {
      expect(HyperswitchDate.dateFromString('2023123', 'yyyymmdd')).toBeNull();
      expect(HyperswitchDate.dateFromString('', 'yyyymmdd')).toBeNull();
    });

    it('returns null for non-numeric input', () => {
      expect(HyperswitchDate.dateFromString('abcdefgh', 'yyyymmdd')).toBeNull();
    });
  });

  describe('comparison methods', () => {
    const d1 = new HyperswitchDate(1, 1, 2020);
    const d2 = new HyperswitchDate(2, 1, 2020);
    const d3 = new HyperswitchDate(1, 2, 2020);
    const d4 = new HyperswitchDate(1, 1, 2021);

    it('lte works correctly', () => {
      expect(d1.lte(d1)).toBe(true);
      expect(d1.lte(d2)).toBe(true);
      expect(d2.lte(d1)).toBe(false);
      expect(d1.lte(d3)).toBe(true);
      expect(d3.lte(d1)).toBe(false);
      expect(d1.lte(d4)).toBe(true);
      expect(d4.lte(d1)).toBe(false);
    });

    it('gte works correctly', () => {
      expect(d1.gte(d1)).toBe(true);
      expect(d2.gte(d1)).toBe(true);
      expect(d1.gte(d2)).toBe(false);
      expect(d3.gte(d1)).toBe(true);
      expect(d1.gte(d3)).toBe(false);
      expect(d4.gte(d1)).toBe(true);
      expect(d1.gte(d4)).toBe(false);
    });

    it('isBetween works correctly', () => {
      const start = new HyperswitchDate(1, 1, 2020);
      const end = new HyperswitchDate(31, 12, 2020);
      const inside = new HyperswitchDate(15, 6, 2020);
      const before = new HyperswitchDate(31, 12, 2019);
      const after = new HyperswitchDate(1, 1, 2021);

      expect(inside.isBetween(start, end)).toBe(true);
      expect(start.isBetween(start, end)).toBe(true);
      expect(end.isBetween(start, end)).toBe(true);
      expect(before.isBetween(start, end)).toBe(false);
      expect(after.isBetween(start, end)).toBe(false);
    });
  });
});

describe('DateRangeRule', () => {
  const errorMessage = 'Invalid date';

  it('returns false for empty value', () => {
    const rule = new DateRangeRule('mmddyyyy', errorMessage);
    expect(rule.validate('')).toBe(false);
  });

  it('returns false for invalid date string', () => {
    const rule = new DateRangeRule('mmddyyyy', errorMessage);
    expect(rule.validate('abcdefgh')).toBe(false);
  });

  it('returns true if no range is set and date is valid', () => {
    const rule = new DateRangeRule('mmddyyyy', errorMessage);
    expect(rule.validate('01012020')).toBe(true);
  });

  it('validates date within start and end range', () => {
    const start = new HyperswitchDate(1, 1, 2020);
    const end = new HyperswitchDate(31, 12, 2020);
    const rule = new DateRangeRule('mmddyyyy', errorMessage, start, end);

    expect(rule.validate('01012020')).toBe(true); // start
    expect(rule.validate('12312020')).toBe(true); // end
    expect(rule.validate('06302020')).toBe(true); // middle
    expect(rule.validate('12312019')).toBe(false); // before
    expect(rule.validate('01012021')).toBe(false); // after
  });

  it('validates date with only startDate', () => {
    const start = new HyperswitchDate(1, 1, 2020);
    const rule = new DateRangeRule('mmddyyyy', errorMessage, start);

    expect(rule.validate('01012020')).toBe(true);
    expect(rule.validate('12312020')).toBe(true);
    expect(rule.validate('12312019')).toBe(false);
  });

  it('validates date with only endDate', () => {
    const end = new HyperswitchDate(31, 12, 2020);
    const rule = new DateRangeRule('mmddyyyy', errorMessage, undefined, end);

    expect(rule.validate('01012020')).toBe(true);
    expect(rule.validate('12312020')).toBe(true);
    expect(rule.validate('01012021')).toBe(false);
  });

  it('works with ddmmyyyy format', () => {
    const start = new HyperswitchDate(1, 1, 2020);
    const end = new HyperswitchDate(31, 12, 2020);
    const rule = new DateRangeRule('ddmmyyyy', errorMessage, start, end);

    expect(rule.validate('01012020')).toBe(true);
    expect(rule.validate('31122020')).toBe(true);
    expect(rule.validate('31122019')).toBe(false);
  });

  it('works with yyyymmdd format', () => {
    const start = new HyperswitchDate(1, 1, 2020);
    const end = new HyperswitchDate(31, 12, 2020);
    const rule = new DateRangeRule('yyyymmdd', errorMessage, start, end);

    expect(rule.validate('20200101')).toBe(true);
    expect(rule.validate('20201231')).toBe(true);
    expect(rule.validate('20191231')).toBe(false);
  });

  it('returns false for invalid date string length', () => {
    const rule = new DateRangeRule('mmddyyyy', errorMessage);
    expect(rule.validate('1231202')).toBe(false);
  });
});
