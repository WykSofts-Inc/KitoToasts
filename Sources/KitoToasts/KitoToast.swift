//
//  KitoToast.swift
//  KitoToasts
//
//  Created by Wycliff on 3/9/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import KitoCore

public enum KitoToastStyle: Equatable, Sendable {
    case success, error, warning, info
}

/// Which SF Symbol a toast shows. `.automatic` derives it from `style`
/// (the common case); `.custom` overrides it for a specific toast;
/// `.none` hides the icon entirely.
public enum KitoToastIcon: Equatable, Sendable {
    case automatic
    case custom(String)
    case none
}

/// How large/prominent a toast's title reads. Actual fonts come from
/// `KitoToastAppearance` — this just selects which of its three font slots
/// to use, so app-wide restyling doesn't require touching individual toasts.
public enum KitoToastTitleStyle: Sendable {
    case large, medium, small
}

/// Which semantic color an action button takes — independent of the
/// toast's own `style`, since a success toast can still offer a
/// destructive action ("Undo" on a delete-confirmation-style toast).
public enum KitoToastActionRole: Equatable, Sendable {
    case primary, destructive, cancel
}

/// What an action button actually shows. `icon` on `KitoToastAction` is
/// ignored when this is `.titleOnly`, and an icon-only button with no
/// `icon` set just falls back to its title, so a screen can't end up with
/// a blank, untappable-looking button.
public enum KitoToastActionContent: Equatable, Sendable {
    case titleOnly
    case iconOnly
    case iconAndTitle
}

/// One button in a toast's action row. A toast can carry several — pass
/// multiple `KitoToastAction`s to `actions:` for e.g. "Undo" + "View".
public struct KitoToastAction: Sendable {
    public var title: String
    public var icon: String?
    public var content: KitoToastActionContent
    public var role: KitoToastActionRole
    public var handler: @MainActor @Sendable () -> Void

    public init(
        title: String,
        icon: String? = nil,
        content: KitoToastActionContent = .titleOnly,
        role: KitoToastActionRole = .primary,
        handler: @escaping @MainActor @Sendable () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.content = content
        self.role = role
        self.handler = handler
    }
}

/// A live 0...1 fill for an in-progress toast (an upload, a sync, a
/// download) — set on the toast that `KitoToastCenter.show(_:)` first
/// displays, then advanced in place with `KitoToastCenter.updateProgress
/// (id:fraction:)` so the bar animates smoothly instead of the toast being
/// replaced frame to frame. Finish the flow with `KitoToastCenter.complete
/// (id:style:title:message:)`, which morphs the same toast into a normal
/// success/error state rather than dismissing and queuing a new one.
public struct KitoToastProgress: Equatable, Sendable {
    public var fraction: Double

    public init(fraction: Double) {
        self.fraction = min(max(fraction, 0), 1)
    }
}

/// One queued toast. `message` is the only required text — `title` is an
/// optional, more prominent headline above it (pair with `titleStyle: .large`
/// for an attention-grabbing banner). `duration` of `nil` means it stays
/// until dismissed — the default whenever `actions` is non-empty, since a
/// toast the user is meant to respond to shouldn't vanish out from under them.
public struct KitoToast: Identifiable, Sendable {
    public let id: UUID
    public var title: String?
    public var message: String
    public var style: KitoToastStyle
    public var icon: KitoToastIcon
    public var titleStyle: KitoToastTitleStyle
    public var isBold: Bool
    public var accentColor: Color?
    /// Overrides the app-wide `KitoToastAppearance.backgroundStyle` for just
    /// this toast — e.g. a gradient or image background for one celebratory
    /// "achievement unlocked" toast, while everything else stays on the
    /// default material background.
    public var backgroundStyle: KitoBackgroundStyle?
    public var actions: [KitoToastAction]
    public var progress: KitoToastProgress?
    public var duration: TimeInterval?

    public init(
        id: UUID = UUID(),
        title: String? = nil,
        message: String,
        style: KitoToastStyle = .info,
        icon: KitoToastIcon = .automatic,
        titleStyle: KitoToastTitleStyle = .medium,
        isBold: Bool = false,
        accentColor: Color? = nil,
        backgroundStyle: KitoBackgroundStyle? = nil,
        actions: [KitoToastAction] = [],
        progress: KitoToastProgress? = nil,
        duration: TimeInterval? = 3
    ) {
        self.id = id
        self.title = title
        self.message = message
        self.style = style
        self.icon = icon
        self.titleStyle = titleStyle
        self.isBold = isBold
        self.accentColor = accentColor
        self.backgroundStyle = backgroundStyle
        self.actions = actions
        self.progress = progress
        // A toast tracking progress stays up until `KitoToastCenter.complete`
        // morphs it, same reasoning as actions: nothing with unfinished
        // work to report should be able to auto-dismiss out from under it.
        self.duration = (actions.isEmpty && progress == nil) ? duration : nil
    }
}
