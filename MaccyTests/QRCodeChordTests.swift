import AppKit
import Testing
import Sauce
@testable import Maccy

@MainActor
struct QRCodeChordTests {
  @Test("Option-Q maps to the QR code chord")
  func optionQShowsQRCode() {
    #expect(KeyChord(.q, [.option]) == .showQRCode)
  }

  @Test("Plain Q is not the QR code chord")
  func plainQIsNotQRCode() {
    #expect(KeyChord(.q, []) != .showQRCode)
  }

  @Test("Command-Q is not the QR code chord")
  func commandQIsNotQRCode() {
    #expect(KeyChord(.q, [.command]) != .showQRCode)
  }
}
