//
//  KitoToastCenter.swift
//  KitoToasts
//
//  Created by Wycliff on 3/10/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import Observation
import KitoCore

/// Owns the toast queue for one screen (or the whole app, if hosted at the
/// root). Only one toast is on screen at a time — `show` enqueues, the host
/// view drains the queue as each toast's lifetime ends.
///
/// `@MainActor`-isolated because it's a UI-bound ViewModel driven by
/// SwiftUI: the auto-dismiss `Task` below inherits this actor from its
/// creation context, so it can call back into `self` after `Task.sleep`
/// without an explicit `MainActor.run` hop.
@Observable
@MainActor
public final class KitoToastCenter: KitoViewModel {
    public private(set) var current: KitoToast?
    public var position: KitoToastPosition
    private var queue: [KitoToast] = []
    private var dismissTask: Task<Void, Never>?

    public init(position: KitoToastPosition = .top) {
        self.position = position
    }

    public func show(_ toast: KitoToast) {
        queue.append(toast)
        if current == nil { advance() }
    }

    public func show(_ message: String, style: KitoToastStyle = .info, duration: TimeInterval? = 3) {
        show(KitoToast(message: message, style: style, duration: duration))
    }

    public func dismissCurrent() {
        dismissTask?.cancel()
        current = nil
        advance()
    }

    /// Advances a progress toast's fill in place — the same toast slot
    /// keeps animating rather than being replaced, which is what makes the
    /// bar read as one continuous upload instead of a flicker of new toasts.
    /// A no-op if `id` isn't the toast currently on screen (it already
    /// finished, or was dismissed).
    public func updateProgress(id: UUID, fraction: Double) {
        guard current?.id == id else { return }
        current?.progress = KitoToastProgress(fraction: fraction)
    }

    /// Morphs the current progress toast into a normal success/error/etc.
    /// state — same toast, same slot, no dismiss-then-requeue flicker. Ends
    /// the "in progress, can't auto-dismiss" hold: the resulting toast
    /// follows `duration` (`3` seconds by default) like any other.
    public func complete(id: UUID, style: KitoToastStyle, title: String? = nil, message: String? = nil, duration: TimeInterval? = 3) {
        guard current?.id == id else { return }
        current?.progress = nil
        current?.style = style
        if let title { current?.title = title }
        if let message { current?.message = message }
        current?.duration = duration
        if let duration {
            dismissTask?.cancel()
            dismissTask = Task { [weak self] in
                try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
                guard !Task.isCancelled else { return }
                self?.dismissCurrent()
            }
        }
    }

    private func advance() {
        guard current == nil, !queue.isEmpty else { return }
        let next = queue.removeFirst()
        current = next
        if let duration = next.duration {
            dismissTask = Task { [weak self] in
                try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
                guard !Task.isCancelled else { return }
                self?.dismissCurrent()
            }
        }
    }
}
