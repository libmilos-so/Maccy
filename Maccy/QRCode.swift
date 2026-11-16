import AppKit
import CoreImage.CIFilterBuiltins

// Generates QR codes on-device with Core Image, so clipboard text can be moved
// to another device without leaving the machine.
enum QRCode {
  // Error correction "M" recovers up to 15% of damaged modules — the standard
  // middle ground between code density and resilience.
  private static let errorCorrectionLevel = "M"
  // Upscaling applied before rasterising. Core Image emits one pixel per
  // module (quiet zone included), so the transform is what keeps module
  // edges crisp under any later resampling.
  static let rasterisationScale: CGFloat = 10
  // Largest payload we encode, in bytes of UTF-8. The QR specification allows
  // far more (2331 bytes at error correction "M", i.e. 177 data modules), but
  // codes near that ceiling do not decode reliably: some payloads fail at
  // every rendered size, others only at particular render scales — verified
  // with Vision's VNDetectBarcodesRequest. 1000 bytes (121 data modules)
  // stays well clear of that unreliable region.
  static let maximumPayloadByteCount = 1000
  // Rasterising runs on the popup's interaction path, so a single reusable
  // context avoids paying context setup on every generation.
  private static let context = CIContext()

  // Single source of truth for encodability: callers ask this instead of
  // comparing against the byte limit, so the rule cannot drift from the
  // generator's own guards.
  static func canEncode(_ text: String) -> Bool {
    !text.isEmpty && text.utf8.count <= maximumPayloadByteCount
  }

  static func image(for text: String) -> NSImage? {
    guard canEncode(text) else {
      return nil
    }

    let filter = CIFilter.qrCodeGenerator()
    filter.message = Data(text.utf8)
    filter.correctionLevel = errorCorrectionLevel
    guard let outputImage = filter.outputImage else {
      return nil
    }

    // Scale with a transform before rasterising so modules stay square and
    // hard-edged. Scaling a rendered bitmap smears the modules and scanners
    // struggle with the result.
    let scaledImage = outputImage.transformed(
      by: CGAffineTransform(scaleX: rasterisationScale, y: rasterisationScale)
    )
    guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else {
      return nil
    }

    return NSImage(
      cgImage: cgImage,
      size: NSSize(width: scaledImage.extent.width, height: scaledImage.extent.height)
    )
  }
}
