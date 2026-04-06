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
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            let image = NSImage(named: NSImage.Name("AppIcon")) ?? NSApp.applicationIconImage
            image?.isTemplate = false
            button.image = image
            button.imagePosition = .imageOnly
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
}
