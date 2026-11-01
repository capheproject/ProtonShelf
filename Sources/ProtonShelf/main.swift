import AppKit
import ServiceManagement

// ProtonShelf puts one icon in the menu bar. Clicking it drops down a menu of
// every installed Proton app; choosing one opens it (or brings it forward).
// Hold ⌥ while the menu is open to turn each entry into "Quit …".

final class Shelf: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let menu = NSMenu()

    func applicationDidFinishLaunching(_ notification: Notification) {
        item.autosaveName = "ProtonShelf"
        if let button = item.button {
            let image = NSImage(systemSymbolName: "atom", accessibilityDescription: "Proton apps")
            image?.isTemplate = true
            button.image = image
            button.toolTip = "Proton apps"
        }
        menu.delegate = self
        item.menu = menu
    }

    // Rebuilt every time it opens so running state and new installs are current.
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        let apps = installedProtonApps()
        if apps.isEmpty {
            let none = NSMenuItem(title: "No Proton apps found in Applications", action: nil, keyEquivalent: "")
            none.isEnabled = false
            menu.addItem(none)
        }

        for url in apps {
            let name = displayName(url)
            let running = runningApp(for: url)
            let icon = NSWorkspace.shared.icon(forFile: url.path)
            icon.size = NSSize(width: 18, height: 18)

            let open = NSMenuItem(title: name, action: #selector(openApp(_:)), keyEquivalent: "")
            open.target = self
            open.representedObject = url
            open.image = icon
            open.state = running != nil ? .on : .off
            open.onStateImage = runningDot()
            menu.addItem(open)

            let quit = NSMenuItem(title: "Quit \(name)", action: #selector(quitApp(_:)), keyEquivalent: "")
            quit.target = self
            quit.representedObject = url
            quit.image = icon
            quit.isAlternate = true
            quit.keyEquivalentModifierMask = .option
            quit.isEnabled = running != nil
            menu.addItem(quit)
        }

        menu.addItem(.separator())

        let openAll = NSMenuItem(title: "Open All", action: #selector(openAll), keyEquivalent: "")
        openAll.target = self
        menu.addItem(openAll)

        let login = NSMenuItem(title: "Open ProtonShelf at Login", action: #selector(toggleLogin), keyEquivalent: "")
        login.target = self
        login.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(login)

        menu.addItem(NSMenuItem(title: "Quit ProtonShelf", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    }

    // MARK: Actions

    @objc private func openApp(_ sender: NSMenuItem) {
        guard let url = sender.representedObject as? URL else { return }
        let config = NSWorkspace.OpenConfiguration()
        config.activates = true
        // Opening an already-running app sends it a "reopen", which makes
        // menu-bar-style apps like VPN, Pass and Bridge show their window.
        NSWorkspace.shared.openApplication(at: url, configuration: config)
    }

    @objc private func quitApp(_ sender: NSMenuItem) {
        guard let url = sender.representedObject as? URL else { return }
        runningApp(for: url)?.terminate()
    }

    @objc private func openAll() {
        let config = NSWorkspace.OpenConfiguration()
        config.activates = false
        for url in installedProtonApps() where runningApp(for: url) == nil {
            NSWorkspace.shared.openApplication(at: url, configuration: config)
        }
    }

    @objc private func toggleLogin() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            NSAlert(error: error).runModal()
        }
    }

    // MARK: Helpers

    private func installedProtonApps() -> [URL] {
        let fm = FileManager.default
        let dirs = [URL(fileURLWithPath: "/Applications"),
                    fm.homeDirectoryForCurrentUser.appendingPathComponent("Applications")]
        let apps = dirs.flatMap { dir in
            (try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)) ?? []
        }.filter { url in
            url.pathExtension == "app" && url.lastPathComponent.lowercased().hasPrefix("proton")
                && Bundle(url: url)?.bundleIdentifier != Bundle.main.bundleIdentifier
        }
        // Alphabetical, except Pass goes last: it's usually the one not running.
        return apps.sorted { a, b in
            let aLast = isPass(a), bLast = isPass(b)
            if aLast != bLast { return bLast }
            return displayName(a).localizedStandardCompare(displayName(b)) == .orderedAscending
        }
    }

    private func isPass(_ url: URL) -> Bool {
        displayName(url).lowercased().contains("pass")
    }

    private func displayName(_ url: URL) -> String {
        FileManager.default.displayName(atPath: url.path).replacingOccurrences(of: ".app", with: "")
    }

    private func runningApp(for url: URL) -> NSRunningApplication? {
        guard let id = Bundle(url: url)?.bundleIdentifier else { return nil }
        return NSRunningApplication.runningApplications(withBundleIdentifier: id).first
    }

    private func runningDot() -> NSImage {
        NSImage(size: NSSize(width: 8, height: 8), flipped: false) { rect in
            NSColor.systemGreen.setFill()
            NSBezierPath(ovalIn: rect.insetBy(dx: 1, dy: 1)).fill()
            return true
        }
    }
}

let app = NSApplication.shared
let shelf = Shelf()
app.delegate = shelf
app.setActivationPolicy(.accessory)
app.run()
