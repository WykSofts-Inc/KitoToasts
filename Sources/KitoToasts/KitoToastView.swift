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
    let toast: KitoToast
    let onDismiss: () -> Void

    @State private var iconScale: CGFloat = 0.4
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        HStack(spacing: theme.spacing.sm) {
            Rectangle()
                .fill(accentColor)
                .frame(width: 4)
                .clipShape(RoundedRectangle(cornerRadius: 2))

            Image(systemName: iconName)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(accentColor)
                .scaleEffect(iconScale)
                .padding(.leading, theme.spacing.xs)

            Text(toast.message)
                .font(theme.typography.body)
                .foregroundStyle(theme.colors.onSurface)
                .lineLimit(2)

            Spacer(minLength: 0)

            if let action = toast.action {
                Button(action.title) {
                    action.handler()
                    onDismiss()
                }
                .font(theme.typography.label.bold())
                .foregroundStyle(theme.colors.primary)
            }
        }
        .padding(.vertical, theme.spacing.sm)
        .padding(.trailing, theme.spacing.md)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: theme.radii.lg))
        .overlay(RoundedRectangle(cornerRadius: theme.radii.lg).stroke(theme.colors.border, lineWidth: 1))
        .shadow(color: .black.opacity(0.15), radius: 16, y: 6)
        .padding(.horizontal, theme.spacing.md)
        // `.overlay(alignment:)` on KitoToastHost proposes the FULL screen
        // size to this view, not just its natural size — `alignment` only
        // positions within that proposal, it doesn't shrink-wrap it. Without
        // this, the Spacer() above expands to fill the entire proposed
        // height as well as width, stretching the toast to fill the screen.
        // `.fixedSize` forces SwiftUI to use this view's own ideal size
        // instead of the parent's proposal.
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

    private var iconName: String {
        switch toast.style {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }

    private var accentColor: Color {
        switch toast.style {
        case .success: return theme.colors.success
        case .error: return theme.colors.danger
        case .warning: return theme.colors.warning
        case .info: return theme.colors.primary
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
