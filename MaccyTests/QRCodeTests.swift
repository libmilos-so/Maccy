import AppKit
import Testing
import Vision
@testable import Maccy

@MainActor
struct QRCodeTests {
  @Test("QR code from non-empty text")
  func qrCodeFromText() {
    #expect(QRCode.image(for: "https://maccy.app") != nil)
  }

  @Test("QR code image is square")
  func qrCodeImageIsSquare() {
    let image = QRCode.image(for: "Maccy")
    #expect(image != nil)
    #expect(image?.size.width == image?.size.height)
    #expect((image?.size.width ?? 0) > 0)
  }

  @Test("QR code from empty text is nil")
  func qrCodeFromEmptyText() {
    #expect(QRCode.image(for: "") == nil)
  }

  @Test("QR code from oversized text is nil")
  func qrCodeFromOversizedText() {
    // Beyond the 1000-byte payload cap: denser codes render but do not decode.
    #expect(QRCode.image(for: String(repeating: "a", count: 3000)) == nil)
    #expect(QRCode.image(for: String(repeating: "a", count: QRCode.maximumPayloadByteCount + 1)) == nil)
  }

  @Test("QR code view side clamps short codes to the minimum")
  func qrCodeViewSideForShortCode() {
    // 27 modules is what the generator emits for a short URL.
    let image = NSImage(size: NSSize(width: 27 * QRCode.rasterisationScale, height: 27 * QRCode.rasterisationScale))
    #expect(QRCodeView.side(for: image) == QRCodeView.minimumSide)
  }

  @Test("QR code view side clamps dense codes to the maximum")
  func qrCodeViewSideForDenseCode() {
    // 123 modules is the densest code the generator emits (a full 1000-byte payload).
    let image = NSImage(size: NSSize(width: 123 * QRCode.rasterisationScale, height: 123 * QRCode.rasterisationScale))
    #expect(QRCodeView.side(for: image) == QRCodeView.maximumSide)
  }

  @Test("canEncode accepts a payload at the byte limit")
  func canEncodeAtByteLimit() {
    #expect(QRCode.canEncode(String(repeating: "a", count: QRCode.maximumPayloadByteCount)))
  }

  @Test("canEncode rejects a payload over the byte limit")
  func canEncodeOverByteLimit() {
    #expect(!QRCode.canEncode(String(repeating: "a", count: QRCode.maximumPayloadByteCount + 1)))
  }

  @Test("canEncode counts bytes, not characters")
  func canEncodeCountsBytesNotCharacters() {
    // 'ä' is two bytes in UTF-8: 500 of them fill the limit exactly.
    let atLimit = String(repeating: "ä", count: QRCode.maximumPayloadByteCount / 2)
    #expect(QRCode.canEncode(atLimit))
    #expect(!QRCode.canEncode(atLimit + "ä"))
  }

  @Test("canEncode rejects empty text")
  func canEncodeEmptyText() {
    #expect(!QRCode.canEncode(""))
  }

  @Test("QR code at the payload limit decodes back to its text")
  func qrCodeAtPayloadLimitDecodes() throws {
    let payload = String(repeating: "a", count: QRCode.maximumPayloadByteCount)
    #expect(QRCode.canEncode(payload))
    let image = try #require(QRCode.image(for: payload))
    let decoded = try decodedPayload(of: image)
    #expect(decoded == payload)
  }

  // The generated code must be readable, not merely produced: render it into a
  // bitmap the way the view displays it (nearest-neighbour over white at the
  // view's side length) and decode with the Vision request a scanner app uses.
  private func decodedPayload(of image: NSImage) throws -> String? {
    let side = QRCodeView.side(for: image)
    let rep = try #require(
      NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(side),
        pixelsHigh: Int(side),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
      )
    )
    NSGraphicsContext.saveGraphicsState()
    defer { NSGraphicsContext.restoreGraphicsState() }
    let context = try #require(NSGraphicsContext(bitmapImageRep: rep))
    NSGraphicsContext.current = context
    context.imageInterpolation = .none
    NSColor.white.setFill()
    NSRect(x: 0, y: 0, width: side, height: side).fill()
    image.draw(in: NSRect(x: 0, y: 0, width: side, height: side))

    let request = VNDetectBarcodesRequest()
    let handler = VNImageRequestHandler(cgImage: try #require(rep.cgImage), options: [:])
    try handler.perform([request])
    return request.results?.compactMap(\.payloadStringValue).first
  }
}
