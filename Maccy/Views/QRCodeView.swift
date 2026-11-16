import SwiftUI

struct QRCodeView: View {
  // Short codes stay at the minimum; dense codes grow up to the maximum so
  // their modules stay scannable (see side(for:)).
  static let minimumSide: CGFloat = 200
  static let maximumSide: CGFloat = 480
  static let padding: CGFloat = 16

  let image: NSImage
  let text: String

  // The image's width divided by the rasterisation scale gives the module
  // count — Core Image emits one pixel per module, quiet zone included — and
  // sizing the code from that count keeps modules readable where a fixed
  // square would render dense codes too small to scan.
  static func side(for image: NSImage) -> CGFloat {
    let moduleCount = image.size.width / QRCode.rasterisationScale
    return min(max(moduleCount * Self.pointsPerModule, minimumSide), maximumSide)
  }
  private static let pointsPerModule: CGFloat = 4

  var body: some View {
    let side = Self.side(for: image)

    Image(nsImage: image)
      .resizable()
      // Never smooth the modules; scanners need hard module edges.
      .interpolation(.none)
      .scaledToFit()
      .frame(width: side, height: side)
      .padding(Self.padding)
      // Keep the backdrop light even in dark mode so the code stays scannable.
      .background(.white)
      .accessibilityLabel(
        // Follow HistoryItem.generateTitle()'s 1k truncation so VoiceOver
        // never reads an entire long payload aloud.
        String(
          format: NSLocalizedString("qr_code_accessibility_label", comment: ""),
          text.shortened(to: 1_000)
        )
      )
  }
}

// Shown in the QR window when an item has no encodable text: a one-line
// explanation on the same white backdrop as the code, sized to the text.
// Colours are fixed because the window itself is always white (see QRCodeWindow).
struct QRCodeMessageView: View {
  let message: String

  var body: some View {
    Text(message)
      // Cap the width so a long localization wraps instead of widening the
      // window past the screen edge, where the origin clamp would push it
      // off-screen; fittingSize picks up the wrapped height.
      .frame(maxWidth: 400)
      .foregroundStyle(.black)
      .padding(QRCodeView.padding)
      .background(.white)
      .accessibilityLabel(message)
  }
}

#Preview {
  QRCodeView(
    image: QRCode.image(for: "https://maccy.app")!,
    text: "https://maccy.app"
  )
  .environment(\.locale, .init(identifier: "en"))
}
