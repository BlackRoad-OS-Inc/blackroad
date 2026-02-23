import AppKit
import SwiftUI

// ── Entry point ───────────────────────────────────────────────
// Run this as a macOS app target in Xcode.
// It runs as a menu bar app (no Dock icon) and owns:
//   • Status bar item (⚡ in menu bar)
//   • NSTouchBar on MacBooks with Touch Bar
//   • Floating desktop overlay widget

@main
struct BlackRoadMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        // No main window — pure menu bar + touch bar app
        Settings { EmptyView() }
    }
}

// ── App delegate — wires everything together ──────────────────
final class AppDelegate: NSObject, NSApplicationDelegate {

    var statusBar: MenuBarController!
    var touchBar: TouchBarController!
    var desktop: DesktopOverlayController!
    var health = MacHealthService()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // No Dock icon — lives only in menu bar
        NSApp.setActivationPolicy(.accessory)

        statusBar = MenuBarController(health: health)
        touchBar  = TouchBarController(health: health)
        desktop   = DesktopOverlayController(health: health)

        // Attach touch bar to the app's key window provider
        NSApp.touchBar = touchBar.makeTouchBar()

        // Start health polling (every 30 s)
        health.startPolling()

        // Show desktop overlay on launch (user can toggle)
        desktop.show()
    }
}
