let cvcAppearanceToAppearance = (cvcAppearance: PaymentSheetConfiguration.cvcAppearance): PaymentSheetConfiguration.appearance => {
  let appearance: PaymentSheetConfiguration.appearance = {
    colors: ?cvcAppearance.colors,
    shapes: ?cvcAppearance.shapes,
    font: ?cvcAppearance.font,
  }
  appearance
}
