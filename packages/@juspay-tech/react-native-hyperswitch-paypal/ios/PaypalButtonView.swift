import UIKit
import PayPal

class PaypalButtonView: UIView {

  private var payPalButton: PayPalButton?
  private var containerView: UIView?
  private var needsRebuild: Bool = false

  @objc dynamic var buttonColor: String = "gold" {
    didSet { scheduleRebuild() }
  }

  @objc dynamic var buttonLabel: String = "paypal" {
    didSet { scheduleRebuild() }
  }

  @objc dynamic var borderRadius: Double = 0 {
    didSet { scheduleRebuild() }
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupButton()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setupButton()
  }

  private func setupButton() {
    containerView?.removeFromSuperview()
    payPalButton = nil
    containerView = nil

    let color = mapColor(buttonColor)
    let label = mapLabel(buttonLabel)
    let edges = mapEdges(borderRadius)

    let button = PayPalButton(
      color: color,
      edges: edges,
      size: .collapsed,
      label: label
    )
    button.translatesAutoresizingMaskIntoConstraints = false
    button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)

    payPalButton = button

    let container = UIView()
    container.translatesAutoresizingMaskIntoConstraints = false
    container.addSubview(button)

    NSLayoutConstraint.activate([
      button.topAnchor.constraint(equalTo: container.topAnchor),
      button.bottomAnchor.constraint(equalTo: container.bottomAnchor),
      button.leadingAnchor.constraint(equalTo: container.leadingAnchor),
      button.trailingAnchor.constraint(equalTo: container.trailingAnchor),
    ])

    addSubview(container)
    containerView = container

    NSLayoutConstraint.activate([
      container.topAnchor.constraint(equalTo: topAnchor),
      container.bottomAnchor.constraint(equalTo: bottomAnchor),
      container.leadingAnchor.constraint(equalTo: leadingAnchor),
      container.trailingAnchor.constraint(equalTo: trailingAnchor),
    ])
  }

  private func scheduleRebuild() {
    guard !needsRebuild else { return }
    needsRebuild = true
    DispatchQueue.main.async { [weak self] in
      guard let self = self, self.needsRebuild else { return }
      self.needsRebuild = false
      self.setupButton()
    }
  }

  private func mapColor(_ value: String) -> PayPalButton.Color {
    switch value.lowercased() {
    case "BLUE": return .blue
    case "SILVER": return .silver
    case "WHITE": return .white
    case "BLACK": return .black
    default: return .gold
    }
  }

  private func mapLabel(_ value: String) -> PayPalButton.Label? {
    switch value.lowercased() {
    case "CHECKOUT": return .checkout
    case "BUYNOW": return .buyNow
    case "PAY": return .payWith
    default: return nil
    }
  }

  private func mapEdges(_ radius: Double) -> PaymentButtonEdges {
    if radius <= 0 {
      return .hardEdges
    } else {
      return .custom(CGFloat(radius))
    }
  }

  @objc private func buttonTapped() {
    guard let reactView = superview else { return }
    reactView.reactSubviews().first?.perform(#selector(UIView.didMoveToWindow))
  }

  override var intrinsicContentSize: CGSize {
    return CGSize(width: UIView.noIntrinsicMetric, height: 48)
  }
}
