
let cardNumberInputTestId = "CardNumberInputTestId"
let expiryInputTestId = "ExpiryInputTestId"
let cvcInputTestId = "CVCInputTestId"
let cardholderNameInputTestId = "CardholderNameInputTestId"

/*
 * The inline validation message. Every field's error carries the same id: they are never on screen
 * together in a way that needs telling apart — each sits under its own field, and the fused layout
 * shows at most one — and a merchant asserting "an error is showing" should not have to know which
 * field produced it. Before this, an error `Text` was indistinguishable from a floating label or a
 * placeholder overlay, which are also `Text`.
 */
let errorTextTestId = "CardFieldErrorTestId"

/* Co-badge network chooser. */
let networkTrigger = "CardNetworkTriggerTestId"
let networkHeading = "CardNetworkHeadingTestId"
let networkBackdrop = "CardNetworkBackdropTestId"
let networkOption = scheme => `CardNetworkOption-${scheme}`

/* Scan card. */
let scanCardButton = "ScanCardButtonTestId"
