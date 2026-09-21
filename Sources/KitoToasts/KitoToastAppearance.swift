//
//  KitoToastAppearance.swift
//  KitoToasts
//
//  Created by Wycliff on 3/9/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import KitoCore

/// App-wide toast styling — fonts per title size, corner radius, background,
/// whether the colored accent bar shows, icon size, and line limits. Set
/// once via `.kitoToastAppearance(_:)` near your app's root; every toast
/// reads it through the environment the same way charts read
/// `kitoChartTheme`. Per-toast fields (`KitoToast.isBold`, `.icon`,
/// `.accentColor`, `.backgroundStyle`) layer on top of this for one-off overrides.
public struct KitoToastAppearance: Sendable {
    public var largeTitleFont: Font
    public var mediumTitleFont: Font
    public var smallTitleFont: Font
    public var messageFont: Font
    public var cornerRadius: CGFloat
    public var showsAccentBar: Bool
    public var iconSize: CGFloat
    public var maxTitleLines: Int
    public var maxMessageLines: Int
    public var maxWidth: CGFloat?
    /// `nil` keeps the original `.ultraThinMaterial` look — set this to give
    /// every toast in the app a color, gradient, or image background by default.
    public var backgroundStyle: KitoBackgroundStyle?

    public init(
        largeTitleFont: Font = .system(size: 20, weight: .bold),
        mediumTitleFont: Font = .system(size: 16, weight: .semibold),
        smallTitleFont: Font = .system(size: 14, weight: .medium),
        messageFont: Font = .system(size: 14, weight: .regular),
        cornerRadius: CGFloat = 16,
        showsAccentBar: Bool = true,
        iconSize: CGFloat = 18,
        maxTitleLines: Int = 2,
        maxMessageLines: Int = 3,
        maxWidth: CGFloat? = 480,
        backgroundStyle: KitoBackgroundStyle? = nil
    ) {
        self.largeTitleFont = largeTitleFont
        self.mediumTitleFont = mediumTitleFont
        self.smallTitleFont = smallTitleFont
        self.messageFont = messageFont
        self.cornerRadius = cornerRadius
        self.showsAccentBar = showsAccentBar
        self.iconSize = iconSize
        self.maxTitleLines = maxTitleLines
        self.maxMessageLines = maxMessageLines
        self.maxWidth = maxWidth
        self.backgroundStyle = backgroundStyle
    }

    public func titleFont(for style: KitoToastTitleStyle) -> Font {
        switch style {
        case .large: return largeTitleFont
        case .medium: return mediumTitleFont
        case .small: return smallTitleFont
        }
    }

    public static let `default` = KitoToastAppearance()
}

private struct KitoToastAppearanceKey: EnvironmentKey {
    static let defaultValue: KitoToastAppearance = .default
}

public extension EnvironmentValues {
    var kitoToastAppearance: KitoToastAppearance {
        get { self[KitoToastAppearanceKey.self] }
        set { self[KitoToastAppearanceKey.self] = newValue }
    }
}

public extension View {
    /// Sets app-wide toast styling for every toast in this subtree —
    /// typically called once, near your app's root.
    func kitoToastAppearance(_ appearance: KitoToastAppearance) -> some View {
        environment(\.kitoToastAppearance, appearance)
    }
}
