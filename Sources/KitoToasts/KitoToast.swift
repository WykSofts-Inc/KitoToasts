//
//  KitoToast.swift
//  KitoToasts
//
//  Created by Wycliff on 3/9/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI

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

/// One button in a toast's action row. A toast can carry several — pass
/// multiple `KitoToastAction`s to `actions:` for e.g. "Undo" + "View".
public struct KitoToastAction: Sendable {
    public var title: String
    public var role: KitoToastActionRole
    public var handler: @MainActor @Sendable () -> Void

    public init(
        title: String,
        role: KitoToastActionRole = .primary,
        handler: @escaping @MainActor @Sendable () -> Void
    ) {
        self.title = title
        self.role = role
        self.handler = handler
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
    public var actions: [KitoToastAction]
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
        actions: [KitoToastAction] = [],
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
        self.actions = actions
        self.duration = actions.isEmpty ? duration : nil
    }
}
