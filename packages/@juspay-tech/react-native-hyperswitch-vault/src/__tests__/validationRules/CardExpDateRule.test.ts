import { CardExpDateRule } from '../../utils/validators/CardExpDateRule';

describe('CardExpDateRule', () => {
  const mockDate = new Date('2024-05-15');
  const originalDate = Date;

  beforeAll(() => {
    global.Date = class extends Date {
      constructor() {
        super(mockDate.getTime());
      }
    } as any;
  });

  afterAll(() => {
    global.Date = originalDate;
  });

  it('should validate valid expiration dates', () => {
    const ruleMMYY = new CardExpDateRule('mmyy', 'Error message');
    expect(ruleMMYY.validate('0624')).toBe(true); // June 2024
    expect(ruleMMYY.validate('1226')).toBe(true); // December 2026

    const ruleMMYYYY = new CardExpDateRule('mmyyyy', 'Error message');
    expect(ruleMMYYYY.validate('062024')).toBe(true); // June 2024
    expect(ruleMMYYYY.validate('122026')).toBe(true); // December 2026
  });

  it('should invalidate past expiration dates', () => {
    const ruleMMYY = new CardExpDateRule('mmyy', 'Error message');
    expect(ruleMMYY.validate('0424')).toBe(false); // April 2024
    expect(ruleMMYY.validate('1223')).toBe(false); // December 2023

    const ruleMMYYYY = new CardExpDateRule('mmyyyy', 'Error message');
    expect(ruleMMYYYY.validate('042024')).toBe(false); // April 2024
    expect(ruleMMYYYY.validate('122023')).toBe(false); // December 2023
  });
});
