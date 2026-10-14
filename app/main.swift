import AppKit

private let modeFile = URL(fileURLWithPath: "/Library/Application Support/AWDL Manager/mode")

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

    private var isOn: Bool {
        (try? String(contentsOf: modeFile, encoding: .utf8))?.hasPrefix("on") == true
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        item.button?.target = self
        item.button?.action = #selector(clicked)
        item.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        refresh()
    }

    @objc private func clicked() {
        if NSApp.currentEvent?.type == .rightMouseUp {
            showMenu()
            return
        }
        do {
            // Atomic write replaces the file, which wakes the helper's directory watch.
            try (isOn ? "off\n" : "on\n").write(to: modeFile, atomically: true, encoding: .utf8)
        } catch {
            NSAlert(error: error).runModal()
        }
        refresh()
    }

    private func showMenu() {
        guard let button = item.button else { return }
        let menu = NSMenu()
        menu.addItem(withTitle: "Quit AWDL Manager", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.height + 4), in: button)
    }

    private func refresh() {
        let on = isOn
        item.button?.image = NSImage(
            systemSymbolName: on ? "antenna.radiowaves.left.and.right" : "antenna.radiowaves.left.and.right.slash",
            accessibilityDescription: on ? "AWDL on" : "AWDL off"
        )
        item.button?.toolTip = on ? "AWDL on. Click to turn off." : "AWDL off. Click to turn on."
    }
}

MainActor.assumeIsolated {
    let delegate = AppDelegate()
    NSApplication.shared.delegate = delegate
    NSApplication.shared.run()
}
