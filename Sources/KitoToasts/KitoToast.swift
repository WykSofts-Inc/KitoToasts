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

public struct KitoToastAction: Sendable {
    public var title: String
    public var handler: @MainActor @Sendable () -> Void

    public init(title: String, handler: @escaping @MainActor @Sendable () -> Void) {
        self.title = title
        self.handler = handler
    }
}

/// One queued toast. `duration` of `nil` means it stays until dismissed
/// (used for toasts carrying an action the user must respond to).
public struct KitoToast: Identifiable, Sendable {
    public let id: UUID
    public var message: String
    public var style: KitoToastStyle
    public var duration: TimeInterval?
    public var action: KitoToastAction?

    public init(
        id: UUID = UUID(),
        message: String,
        style: KitoToastStyle = .info,
        duration: TimeInterval? = 3,
        action: KitoToastAction? = nil
    ) {
        self.id = id
        self.message = message
        self.style = style
        self.duration = action != nil ? nil : duration
        self.action = action
    }
}
