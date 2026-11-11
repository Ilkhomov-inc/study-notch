import AppKit

// Agent app: no Dock icon, no main window. Everything lives in the island by the notch.
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
