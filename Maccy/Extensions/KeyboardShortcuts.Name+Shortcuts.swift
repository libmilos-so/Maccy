import KeyboardShortcuts

extension KeyboardShortcuts.Name {
  static let popup = Self("popup", initial: Shortcut(.c, modifiers: [.command, .shift]))
  static let pin = Self("pin", initial: Shortcut(.p, modifiers: [.option]))
  static let delete = Self("delete", initial: Shortcut(.delete, modifiers: [.option]))
  static let togglePreview = Self("togglePreview", initial: Shortcut(.space, modifiers: [.control]))
  // No initial shortcut so the hotkey stays unassigned until the user
  // records one, rather than taking a chord away from other apps.
  static let showQRCode = Self("showQRCode")
}
