//
//  xmaxxApp.swift
//  xmaxx
//
//  Created by Armen Merikyan on 3/30/26.
//

import Cocoa
import SwiftUI

@main
struct xmaxxApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        if let appIcon = NSImage(named: NSImage.Name("AppIcon")) {
            NSApp.applicationIconImage = appIcon
        }

        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            let menuBarThickness = NSStatusBar.system.thickness
            let iconSideLength = max(16, menuBarThickness - 6)
            let image = makeStatusBarIcon(sideLength: iconSideLength)

            button.image = image
            button.imagePosition = .imageOnly
            button.imageScaling = .scaleProportionallyDown
            button.toolTip = "xmaxx"
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(
            title: "Open xmaxx",
            action: #selector(openMainWindow),
            keyEquivalent: ""
        ))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(
            title: "Quit xmaxx",
            action: #selector(quitApp),
            keyEquivalent: "q"
        ))

        for item in menu.items {
            item.target = self
        }

        statusItem.menu = menu
        self.statusItem = statusItem
    }

    @objc private func openMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.windows.first(where: { $0.canBecomeMain })?.makeKeyAndOrderFront(nil)
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    private func makeStatusBarIcon(sideLength: CGFloat) -> NSImage? {
        guard let sourceImage = NSImage(named: NSImage.Name("AppIcon")) ?? NSApp.applicationIconImage else {
            return nil
        }

        let targetSize = NSSize(width: sideLength, height: sideLength)
        let resizedImage = NSImage(size: targetSize)
        resizedImage.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        sourceImage.draw(
            in: NSRect(origin: .zero, size: targetSize),
            from: .zero,
            operation: .copy,
            fraction: 1
        )
        resizedImage.unlockFocus()
        resizedImage.isTemplate = false
        return resizedImage
    }
}
