//
//  KitoToastWindowHost.swift
//  KitoToasts
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import UIKit
import KitoCore

/// Where `.kitoToastHost` draws its toasts.
public enum KitoToastHostPlacement: Equatable, Sendable {
    /// In the host view's own overlay (the default). Sheets and full-screen
    /// covers presented over the host hide the toasts.
    case overlay
    /// In a separate, pass-through window above the app's windows. Toasts show
    /// over sheets and full-screen covers; touches anywhere else fall through
    /// to the app. The theme and toast appearance in effect where the host is
    /// attached are carried over.
    case window
}

struct KitoToastPlacementHost: ViewModifier {
    let center: KitoToastCenter
    let placement: KitoToastHostPlacement

    @Environment(\.kitoTheme) private var theme
    @Environment(\.kitoToastAppearance) private var appearance

    func body(content: Content) -> some View {
        switch placement {
        case .overlay:
            content.modifier(KitoToastHost(center: center))
        case .window:
            content.background {
                KitoToastWindowAnchor(center: center, theme: theme, appearance: appearance)
                    .frame(width: 0, height: 0)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
    }
}

/// A zero-size view that finds its window scene and keeps a toast window in it
/// for as long as it is on screen.
private struct KitoToastWindowAnchor: UIViewRepresentable {
    let center: KitoToastCenter
    let theme: KitoTheme
    let appearance: KitoToastAppearance

    final class Coordinator {
        var window: KitoToastPassThroughWindow?
        var controller: KitoToastHostingController?
        var rootView: AnyView = AnyView(EmptyView())

        func attach(to sourceWindow: UIWindow?) {
            guard let sourceWindow, let scene = sourceWindow.windowScene else {
                window?.isHidden = true
                window = nil
                controller = nil
                return
            }
            if let window, window.windowScene === scene {
                controller?.sourceWindow = sourceWindow
                return
            }
            let controller = KitoToastHostingController(rootView: rootView)
            controller.view.backgroundColor = .clear
            controller.sourceWindow = sourceWindow
            let window = KitoToastPassThroughWindow(windowScene: scene)
            window.windowLevel = .alert + 1
            window.backgroundColor = .clear
            window.rootViewController = controller
            window.isHidden = false
            self.window = window
            self.controller = controller
        }

        func update(_ rootView: AnyView) {
            self.rootView = rootView
            controller?.rootView = rootView
        }

        func tearDown() {
            window?.isHidden = true
            window = nil
            controller = nil
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> KitoToastAnchorView {
        let view = KitoToastAnchorView()
        let coordinator = context.coordinator
        view.onWindowChange = { [weak coordinator] window in coordinator?.attach(to: window) }
        return view
    }

    func updateUIView(_ uiView: KitoToastAnchorView, context: Context) {
        context.coordinator.update(AnyView(
            Color.clear
                .ignoresSafeArea()
                .modifier(KitoToastHost(center: center))
                .environment(\.kitoTheme, theme)
                .kitoToastAppearance(appearance)
        ))
        if context.coordinator.window == nil { context.coordinator.attach(to: uiView.window) }
    }

    static func dismantleUIView(_ uiView: KitoToastAnchorView, coordinator: Coordinator) {
        uiView.onWindowChange = nil
        coordinator.tearDown()
    }
}

final class KitoToastAnchorView: UIView {
    var onWindowChange: ((UIWindow?) -> Void)?

    override func didMoveToWindow() {
        super.didMoveToWindow()
        onWindowChange?(window)
    }
}

/// Hands status bar decisions back to the app's own window, so the toast
/// window never changes the status bar's style or visibility.
final class KitoToastHostingController: UIHostingController<AnyView> {
    weak var sourceWindow: UIWindow?

    private var underlying: UIViewController? {
        var controller = sourceWindow?.rootViewController
        while let presented = controller?.presentedViewController, !presented.isBeingDismissed {
            controller = presented
        }
        return controller
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { underlying?.preferredStatusBarStyle ?? .default }
    override var prefersStatusBarHidden: Bool { underlying?.prefersStatusBarHidden ?? false }
}

/// A window that only claims touches that land on a toast; everything else
/// goes to the windows below.
final class KitoToastPassThroughWindow: UIWindow {
    override var canBecomeKey: Bool { false }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let hit = super.hitTest(point, with: event), let root = rootViewController?.view else { return nil }
        if #available(iOS 18, *) {
            // SwiftUI content no longer shows up as distinct subviews of the hosting view, so
            // ask the hosting view's own subviews (which do carry SwiftUI's gesture hit areas).
            for subview in root.subviews.reversed() {
                let converted = subview.convert(point, from: root)
                if subview.hitTest(converted, with: event) != nil { return hit }
            }
            return nil
        }
        return hit === root ? nil : hit
    }
}
