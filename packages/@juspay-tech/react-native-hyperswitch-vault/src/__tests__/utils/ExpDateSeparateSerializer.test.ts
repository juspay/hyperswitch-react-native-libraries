import ExpDateSeparateSerializer from '../../utils/serializers/ExpDateSeparateSerializer';

describe('ExpDateSeparateSerializer', () => {
  const monthFieldName = 'month';
  const yearFieldName = 'year';
  const serializer = new ExpDateSeparateSerializer(
    monthFieldName,
    yearFieldName
  );

  it('should serialize date in mmyy format', () => {
    expect(serializer.serialize('1234')).toEqual({
      [monthFieldName]: '12',
      [yearFieldName]: '34',
    });
  });

  it('should serialize date in mmyyyy format', () => {
    expect(serializer.serialize('122028')).toEqual({
      [monthFieldName]: '12',
      [yearFieldName]: '2028',
    });
  });

  it('should handle invalid date format', () => {
    // Currently, it returns empty strings
    expect(serializer.serialize('123')).toEqual({
      [monthFieldName]: '',
      [yearFieldName]: '',
    });
  });

  it('should handle empty input', () => {
    // Currently, it returns empty strings
    expect(serializer.serialize('')).toEqual({
      [monthFieldName]: '',
      [yearFieldName]: '',
    });
  });

  it('should use correct field names', () => {
    const customMonthField = 'expMonth';
    const customYearField = 'expYear';
    const customSerializer = new ExpDateSeparateSerializer(
      customMonthField,
      customYearField
    );
    expect(customSerializer.serialize('122028')).toEqual({
      [customMonthField]: '12',
      [customYearField]: '2028',
    });
  });
});
