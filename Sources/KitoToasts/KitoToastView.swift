//
//  KitoToastView.swift
//  KitoToasts
//
//  Created by Wycliff on 3/12/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import KitoCore

struct KitoToastView: View {
    @Environment(\.kitoTheme) private var theme
    @Environment(\.kitoToastAppearance) private var appearance
    let toast: KitoToast
    let onDismiss: () -> Void

    @State private var iconScale: CGFloat = 0.4
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        HStack(spacing: 0) {
            if appearance.showsAccentBar {
                Rectangle()
                    .fill(accentColor)
                    .frame(width: 4)
                    .frame(maxHeight: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 2))
                Spacer().frame(width: theme.spacing.sm)
            }

            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                HStack(alignment: .top, spacing: theme.spacing.sm) {
                    if let iconName = resolvedIconName {
                        Image(systemName: iconName)
                            .font(.system(size: appearance.iconSize, weight: .bold))
                            .foregroundStyle(accentColor)
                            .scaleEffect(iconScale)
                            .padding(.top, 1)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        if let title = toast.title {
                            Text(title)
                                .font(titleFont)
                                .foregroundStyle(theme.colors.onSurface)
                                .lineLimit(appearance.maxTitleLines)
                        }
                        Text(toast.message)
                            .font(messageFont)
                            .foregroundStyle(theme.colors.onSurface.opacity(toast.title == nil ? 1 : 0.75))
                            .lineLimit(appearance.maxMessageLines)
                    }

                    Spacer(minLength: 0)
                }

                if !toast.actions.isEmpty {
                    HStack(spacing: theme.spacing.md) {
                        ForEach(Array(toast.actions.enumerated()), id: \.offset) { _, action in
                            Button(action.title) {
                                action.handler()
                                onDismiss()
                            }
                            .font(theme.typography.label.bold())
                            .foregroundStyle(color(for: action.role))
                        }
                        Spacer(minLength: 0)
                    }
                }
            }
            .padding(.vertical, theme.spacing.sm)
            .padding(.trailing, theme.spacing.md)
        }
        .frame(maxWidth: appearance.maxWidth)
        .kitoBackground(resolvedBackgroundStyle, cornerRadius: appearance.cornerRadius)
        .overlay(RoundedRectangle(cornerRadius: appearance.cornerRadius).stroke(theme.colors.border, lineWidth: 1))
        .shadow(color: .black.opacity(0.15), radius: 16, y: 6)
        .padding(.horizontal, theme.spacing.md)
        // `.overlay(alignment:)` on KitoToastHost proposes the FULL screen
        // size to this view, not just its natural size — alignment only
        // positions within that proposal, it doesn't shrink-wrap it.
        // `.fixedSize` forces SwiftUI to use this view's own ideal height.
        .fixedSize(horizontal: false, vertical: true)
        .offset(y: dragOffset)
        .opacity(1 - min(abs(dragOffset) / 120, 0.6))
        .gesture(
            DragGesture(minimumDistance: 4)
                .onChanged { drag in
                    // Rubber-band: full motion near origin, resistance as it travels.
                    dragOffset = drag.translation.height * 0.6
                }
                .onEnded { drag in
                    if abs(drag.translation.height) > 50 {
                        onDismiss()
                    } else {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { dragOffset = 0 }
                    }
                }
        )
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.6).delay(0.05)) {
                iconScale = 1
            }
        }
        .accessibilityElement(children: .combine)
    }

    /// Per-toast `backgroundStyle` wins, then the app-wide appearance
    /// default, then the original `.ultraThinMaterial` look so existing
    /// toasts with neither set render exactly as before.
    private var resolvedBackgroundStyle: KitoBackgroundStyle {
        toast.backgroundStyle ?? appearance.backgroundStyle ?? .material
    }

    private var resolvedIconName: String? {
        switch toast.icon {
        case .automatic: return defaultIconName
        case .custom(let name): return name
        case .none: return nil
        }
    }

    private var defaultIconName: String {
        switch toast.style {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }

    private var titleFont: Font {
        let base = appearance.titleFont(for: toast.titleStyle)
        return toast.isBold ? base.bold() : base
    }

    private var messageFont: Font {
        toast.isBold ? appearance.messageFont.bold() : appearance.messageFont
    }

    private var accentColor: Color {
        toast.accentColor ?? defaultAccentColor
    }

    private var defaultAccentColor: Color {
        switch toast.style {
        case .success: return theme.colors.success
        case .error: return theme.colors.danger
        case .warning: return theme.colors.warning
        case .info: return theme.colors.primary
        }
    }

    private func color(for role: KitoToastActionRole) -> Color {
        switch role {
        case .primary: return theme.colors.primary
        case .destructive: return theme.colors.danger
        case .cancel: return theme.colors.onBackground.opacity(0.6)
        }
    }
}

/// Host this once, near the root of your view tree, bound to a
/// `KitoToastCenter` shared by every screen underneath it. Position and
/// entrance edge follow `center.position`.
public struct KitoToastHost: ViewModifier {
    @Bindable var center: KitoToastCenter

    public init(center: KitoToastCenter) {
        self.center = center
    }

    public func body(content: Content) -> some View {
        content.overlay(alignment: center.position == .top ? .top : .bottom) {
            if let toast = center.current {
                KitoToastView(toast: toast) { center.dismissCurrent() }
                    .padding(center.position == .top ? .top : .bottom, 8)
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: center.position == .top ? .top : .bottom).combined(with: .opacity),
                            removal: .scale(scale: 0.9).combined(with: .opacity)
                        )
                    )
                    .zIndex(1)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: center.current?.id)
    }
}

public extension View {
    /// Attach a toast center to this subtree's overlay. Typically called once
    /// on the app's root view.
    func kitoToastHost(_ center: KitoToastCenter) -> some View {
        modifier(KitoToastHost(center: center))
    }
}
