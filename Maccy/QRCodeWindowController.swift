import AppKit
import SwiftUI

// Shows the QR code of a history item — or, when the item has no encodable
// text, a one-line explanation — in a small always-on-top window.
//
// The window is ordered front without activation (orderFrontRegardless) and
// never becomes key (see QRCodeWindow), so the popup stays key: its keyboard
// navigation keeps working while the code is shown, and Esc reaches
// KeyHandlingView, which closes this window before closing the popup.
class QRCodeWindowController {
  private var window: QRCodeWindow?

  var isVisible: Bool {
    window?.isVisible ?? false
  }

  func show(text: String?, relativeTo popupWindow: NSWindow?) {
    // Encoding can fail (e.g. text beyond the payload cap) and an item may
    // have no text at all. Explain in this same window rather than showing a
    // broken image or a dead control.
    let content: NSView
    let size: NSSize
    if let text, let image = QRCode.image(for: text) {
      let side = QRCodeView.side(for: image) + 2 * QRCodeView.padding
      size = NSSize(width: side, height: side)
      content = NSHostingView(rootView: QRCodeView(image: image, text: text))
    } else {
      let message = NSLocalizedString(
        text == nil ? "ShowQRCodeNoText" : "ShowQRCodeTooLong",
        tableName: "PreviewItemView",
        comment: ""
      )
      let view = NSHostingView(rootView: QRCodeMessageView(message: message))
      size = NSSize(width: ceil(view.fittingSize.width), height: ceil(view.fittingSize.height))
      content = view
    }

    let window = self.window ?? QRCodeWindow(contentRect: NSRect(origin: .zero, size: size))
    window.contentView = content
    window.setFrame(positionedFrame(for: size, beside: popupWindow), display: false)
    window.orderFrontRegardless()
    self.window = window
  }

  func close() {
    window?.orderOut(nil)
    window = nil
  }

  // Place the window next to the popup, on whichever side has room, and keep
  // it within the popup's own screen — not NSScreen.forPopup, which resolves
  // to the focused app's screen and may be a different display than the one
  // the popup sits on (the popup follows the mouse in the default mode).
  private func positionedFrame(for size: NSSize, beside popupWindow: NSWindow?) -> NSRect {
    guard let popupFrame = popupWindow?.frame else {
      return NSRect(origin: .zero, size: size)
    }

    let visibleFrame = popupWindow?.screen?.visibleFrame ?? NSScreen.forPopup?.visibleFrame ?? popupFrame
    var origin = NSPoint(
      x: popupFrame.maxX + Self.popupMargin,
      y: popupFrame.midY - size.height / 2
    )

    if origin.x + size.width > visibleFrame.maxX {
      origin.x = popupFrame.minX - Self.popupMargin - size.width
    }
    origin.x = min(max(origin.x, visibleFrame.minX), visibleFrame.maxX - size.width)
    origin.y = min(max(origin.y, visibleFrame.minY), visibleFrame.maxY - size.height)

    return NSRect(origin: origin, size: size)
  }

  private static let popupMargin: CGFloat = 12
}

// A borderless overlay window that never becomes key or main. Taking key
// status would resign the popup's key and FloatingPanel closes itself on
// resignKey, so this window is only ever ordered front (see show).
//
// Click-away dismissal needs no handler here: clicking outside the popup
// resigns its key and FloatingPanel closes itself, which closes this window.
final class QRCodeWindow: NSWindow {
  init(contentRect: NSRect) {
    super.init(
      contentRect: contentRect,
      styleMask: [.borderless],
      backing: .buffered,
      defer: false
    )

    // QR codes need a light, opaque backdrop to scan reliably; the popup is
    // translucent (glass on macOS 26), so this window ignores appearance mode.
    backgroundColor = .white
    isOpaque = true
    // Float above the popup, which sits at .statusBar.
    level = .statusBar + 1
    collectionBehavior = [.auxiliary, .stationary, .moveToActiveSpace, .fullScreenAuxiliary, .ignoresCycle]
    hidesOnDeactivate = false
  }

  override var canBecomeKey: Bool {
    return false
  }

  override var canBecomeMain: Bool {
    return false
  }
}
