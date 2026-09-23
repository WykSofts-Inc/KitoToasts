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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let toast: KitoToast
    let onDismiss: () -> Void

    @State private var iconScale: CGFloat = 0.4
    @State private var dragOffset: CGFloat = 0
    @State private var appeared = false

    var body: some View {
        Group {
            switch toast.layout {
            case .card: card
            case .pill: pill
            case .banner: banner
            case .glass: glass
            case .island: island
            }
        }
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
            withAnimation(reduceMotion ? .easeOut(duration: 0.2) : .spring(response: 0.45, dampingFraction: 0.6).delay(0.05)) {
                iconScale = 1
            }
            appeared = true
        }
        // Plays when the toast appears and again when a loading toast completes.
        .sensoryFeedback(trigger: "\(appeared)-\(toast.style)-\(toast.isLoading)") { _, _ in
            guard appearance.playsHaptics, appeared, !toast.isLoading else { return nil }
            switch toast.style {
            case .success: return .success
            case .error: return .error
            case .warning: return .warning
            case .info: return nil
            }
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: Layouts

    private var card: some View {
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
                    leading(size: appearance.iconSize)
                        .padding(.top, 1)
                    texts(foreground: theme.colors.onSurface)
                    Spacer(minLength: 0)
                    if toast.showsCountdown { countdown(color: accentColor) }
                }
                progressBar(track: theme.colors.surfaceMuted, fill: accentColor)
                actionRow(tint: nil)
            }
            .padding(.vertical, theme.spacing.sm)
            .padding(.trailing, theme.spacing.md)
            .padding(.leading, appearance.showsAccentBar ? 0 : theme.spacing.md)
        }
        .frame(maxWidth: appearance.maxWidth)
        .kitoBackground(resolvedBackgroundStyle, cornerRadius: appearance.cornerRadius)
        .overlay(RoundedRectangle(cornerRadius: appearance.cornerRadius).stroke(theme.colors.border, lineWidth: 1))
        .shadow(color: .black.opacity(0.15), radius: 16, y: 6)
        .padding(.horizontal, theme.spacing.md)
    }

    private var pill: some View {
        HStack(spacing: 10) {
            leading(size: 16)
            Text(toast.title.map { "\($0) · \(toast.message)" } ?? toast.message)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(theme.colors.onSurface)
                .lineLimit(1)
            if toast.showsCountdown { countdown(color: accentColor, size: 18) }
            ForEach(Array(toast.actions.prefix(1).enumerated()), id: \.offset) { _, action in
                Button { action.handler(); onDismiss() } label: { actionLabel(action) }
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(color(for: action.role))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .kitoBackground(resolvedBackgroundStyle, cornerRadius: 30)
        .overlay(Capsule().stroke(theme.colors.border, lineWidth: 1))
        .shadow(color: .black.opacity(0.14), radius: 14, y: 5)
        .padding(.horizontal, theme.spacing.lg)
    }

    private var banner: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            HStack(alignment: .top, spacing: 12) {
                leading(size: 20, color: .white)
                texts(foreground: .white)
                Spacer(minLength: 0)
                if toast.showsCountdown { countdown(color: .white) }
            }
            progressBar(track: .white.opacity(0.3), fill: .white)
            actionRow(tint: .white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LinearGradient(colors: [accentColor, accentColor.opacity(0.82)], startPoint: .topLeading, endPoint: .bottomTrailing))
        .shadow(color: accentColor.opacity(0.35), radius: 16, y: 6)
    }

    private var glass: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            HStack(alignment: .center, spacing: 12) {
                leading(size: 20)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(accentColor.opacity(0.18)))
                texts(foreground: theme.colors.onSurface)
                Spacer(minLength: 0)
                if toast.showsCountdown { countdown(color: accentColor) }
            }
            progressBar(track: theme.colors.onSurface.opacity(0.1), fill: accentColor)
            actionRow(tint: nil)
        }
        .padding(14)
        .frame(maxWidth: appearance.maxWidth)
        .background(RoundedRectangle(cornerRadius: 26, style: .continuous).fill(.ultraThinMaterial))
        .background(RoundedRectangle(cornerRadius: 26, style: .continuous).fill(accentColor.opacity(0.12)).blur(radius: 18).offset(y: 6))
        .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).strokeBorder(.white.opacity(0.28), lineWidth: 1))
        .shadow(color: accentColor.opacity(0.25), radius: 24, y: 10)
        .padding(.horizontal, theme.spacing.md)
    }

    private var island: some View {
        HStack(spacing: 12) {
            leading(size: 18)
                .frame(width: 34, height: 34)
                .background(Circle().fill(accentColor.opacity(0.22)))
            VStack(alignment: .leading, spacing: 1) {
                if let title = toast.title {
                    Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(.white).lineLimit(1)
                }
                Text(toast.message).font(toast.title == nil ? .subheadline.weight(.semibold) : .caption)
                    .foregroundStyle(.white.opacity(toast.title == nil ? 1 : 0.7)).lineLimit(2)
            }
            Spacer(minLength: 0)
            if toast.showsCountdown { countdown(color: accentColor, size: 22) }
            ForEach(Array(toast.actions.prefix(1).enumerated()), id: \.offset) { _, action in
                Button { action.handler(); onDismiss() } label: {
                    actionLabel(action).font(.caption.weight(.bold)).padding(.horizontal, 12).padding(.vertical, 7)
                        .background(Capsule().fill(accentColor)).foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.leading, 10)
        .padding(.trailing, 14)
        .padding(.vertical, 10)
        .background(Capsule(style: .continuous).fill(.black))
        .shadow(color: .black.opacity(0.3), radius: 18, y: 8)
        .padding(.horizontal, 14)
        .environment(\.colorScheme, .dark)
    }

    // MARK: Pieces

    @ViewBuilder
    private func leading(size: CGFloat, color: Color? = nil) -> some View {
        if toast.isLoading {
            ProgressView().controlSize(size > 18 ? .regular : .small).tint(color ?? accentColor)
                .transition(.scale.combined(with: .opacity))
        } else if let avatar = toast.avatar {
            ZStack {
                LinearGradient(colors: avatar.colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                if let symbol = avatar.systemImage {
                    Image(systemName: symbol).font(.system(size: size * 0.9, weight: .bold)).foregroundStyle(.white)
                } else {
                    Text(avatar.initials).font(.system(size: size * 0.75, weight: .bold, design: .rounded)).foregroundStyle(.white)
                }
            }
            .frame(width: size * 2, height: size * 2)
            .clipShape(Circle())
            .scaleEffect(iconScale)
        } else if let iconName = resolvedIconName {
            Image(systemName: iconName)
                .font(.system(size: size, weight: .bold))
                .foregroundStyle(color ?? accentColor)
                .scaleEffect(iconScale)
                .contentTransition(.symbolEffect(.replace))
                .transition(.scale.combined(with: .opacity))
        }
    }

    private func texts(foreground: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            if let title = toast.title {
                Text(title)
                    .font(titleFont)
                    .foregroundStyle(foreground)
                    .lineLimit(appearance.maxTitleLines)
            }
            Text(toast.message)
                .font(messageFont)
                .foregroundStyle(foreground.opacity(toast.title == nil ? 1 : 0.75))
                .lineLimit(appearance.maxMessageLines)
                .contentTransition(.opacity)
        }
    }

    @ViewBuilder
    private func progressBar(track: Color, fill: Color) -> some View {
        if let progress = toast.progress {
            GeometryReader { geo in
                Capsule()
                    .fill(track)
                    .overlay(alignment: .leading) {
                        Capsule()
                            .fill(fill)
                            .frame(width: geo.size.width * progress.fraction)
                    }
            }
            .frame(height: 5)
            .animation(.easeOut(duration: 0.2), value: progress.fraction)
            .padding(.top, 2)
        }
    }

    @ViewBuilder
    private func actionRow(tint: Color?) -> some View {
        if !toast.actions.isEmpty {
            HStack(spacing: theme.spacing.md) {
                ForEach(Array(toast.actions.enumerated()), id: \.offset) { _, action in
                    Button {
                        action.handler()
                        onDismiss()
                    } label: {
                        actionLabel(action)
                    }
                    .font(theme.typography.label.bold())
                    .foregroundStyle(tint ?? color(for: action.role))
                    .accessibilityLabel(action.title)
                }
                Spacer(minLength: 0)
            }
        }
    }

    private func countdown(color: Color, size: CGFloat = 26) -> some View {
        KitoToastCountdown(duration: toast.duration ?? 5, color: color)
            .frame(width: size, height: size)
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

    @ViewBuilder
    private func actionLabel(_ action: KitoToastAction) -> some View {
        switch action.content {
        case .titleOnly:
            Text(action.title)
        case .iconOnly:
            if let icon = action.icon {
                Image(systemName: icon)
            } else {
                Text(action.title)
            }
        case .iconAndTitle:
            HStack(spacing: 4) {
                if let icon = action.icon {
                    Image(systemName: icon)
                }
                Text(action.title)
            }
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

/// A ring that empties over `duration`, with the seconds left inside.
struct KitoToastCountdown: View {
    let duration: TimeInterval
    let color: Color
    @State private var start = Date()

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { context in
            let remaining = max(duration - context.date.timeIntervalSince(start), 0)
            ZStack {
                Circle().stroke(color.opacity(0.2), lineWidth: 2.5)
                Circle().trim(from: 0, to: duration > 0 ? remaining / duration : 0)
                    .stroke(color, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(Int(remaining.rounded(.up)))").font(.system(size: 10, weight: .bold).monospacedDigit()).foregroundStyle(color)
            }
        }
        .accessibilityHidden(true)
    }
}

/// Host this once, near the root of your view tree, bound to a
/// `KitoToastCenter` shared by every screen underneath it. Position and
/// entrance edge follow `center.position`; with `.stack` presentation,
/// toasts pile up and a tap fans them out.
public struct KitoToastHost: ViewModifier {
    @Bindable var center: KitoToastCenter
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var heights: [UUID: CGFloat] = [:]

    public init(center: KitoToastCenter) {
        self.center = center
    }

    private var isTop: Bool { center.position == .top }
    private var edge: Edge { isTop ? .top : .bottom }
    private var animation: Animation { reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.42, dampingFraction: 0.8) }

    public func body(content: Content) -> some View {
        content.overlay(alignment: isTop ? .top : .bottom) {
            ZStack(alignment: isTop ? .top : .bottom) {
                ForEach(Array(center.visible.enumerated()), id: \.element.id) { index, toast in
                    KitoToastView(toast: toast) { center.dismiss(id: toast.id) }
                        .background(GeometryReader { proxy in
                            Color.clear.preference(key: KitoToastHeightsKey.self, value: [toast.id: proxy.size.height])
                        })
                        .scaleEffect(scale(at: index), anchor: isTop ? .bottom : .top)
                        .offset(y: offset(at: index))
                        .opacity(opacity(at: index))
                        .zIndex(Double(center.visible.count - index))
                        .allowsHitTesting(center.isStackExpanded || index == 0)
                        .padding(edge == .top ? .top : .bottom, toast.layout == .banner ? 0 : (toast.layout == .island ? 11 : 8))
                        .ignoresSafeArea(edges: toast.layout == .island || toast.layout == .banner ? edge == .top ? .top : .bottom : [])
                        .transition(
                            .asymmetric(
                                insertion: toast.layout == .island
                                    ? .scale(scale: 0.3, anchor: .top).combined(with: .opacity)
                                    : .move(edge: edge).combined(with: .opacity),
                                removal: .scale(scale: 0.9).combined(with: .opacity)
                            )
                        )
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                guard center.visible.count > 1 else { return }
                withAnimation(animation) { center.isStackExpanded.toggle() }
            }
            .onPreferenceChange(KitoToastHeightsKey.self) { heights = $0 }
            .accessibilityAction(named: center.isStackExpanded ? "Collapse notifications" : "Show all notifications") {
                center.isStackExpanded.toggle()
            }
        }
        .animation(animation, value: center.visible.map(\.id))
        .animation(animation, value: center.isStackExpanded)
    }

    /// How far a toast sits from the front one: stacked, each peeks out 10 points; fanned out,
    /// they lay end to end.
    private func offset(at index: Int) -> CGFloat {
        guard index > 0 else { return 0 }
        let direction: CGFloat = isTop ? 1 : -1
        if center.isStackExpanded {
            let before = center.visible.prefix(index).reduce(CGFloat(0)) { $0 + (heights[$1.id] ?? 64) + 8 }
            return direction * before
        }
        return direction * CGFloat(min(index, 2)) * 10
    }

    private func scale(at index: Int) -> CGFloat {
        center.isStackExpanded ? 1 : 1 - CGFloat(min(index, 3)) * 0.05
    }

    private func opacity(at index: Int) -> Double {
        center.isStackExpanded || index < 3 ? 1 : 0
    }
}

struct KitoToastHeightsKey: PreferenceKey {
    static let defaultValue: [UUID: CGFloat] = [:]
    static func reduce(value: inout [UUID: CGFloat], nextValue: () -> [UUID: CGFloat]) {
        value.merge(nextValue()) { $1 }
    }
}

public extension View {
    /// Attach a toast center to this subtree's overlay. Typically called once
    /// on the app's root view.
    func kitoToastHost(_ center: KitoToastCenter) -> some View {
        modifier(KitoToastHost(center: center))
    }
}
