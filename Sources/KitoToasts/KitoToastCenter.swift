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

/// Whether toasts wait their turn or pile up.
public enum KitoToastPresentation: Equatable, Sendable {
    /// One toast at a time; the rest queue.
    case single
    /// New toasts land on top of a stack, older ones peek out behind; tap the stack to fan it
    /// out. Past `maxVisible`, the oldest goes.
    case stack(maxVisible: Int)

    /// A stack of up to three.
    public static let stacked = KitoToastPresentation.stack(maxVisible: 3)
}

/// Owns the toast queue for one screen (or the whole app, if hosted at the
/// root). In `.single` presentation only one toast is on screen at a time —
/// `show` enqueues, the host view drains the queue as each toast's lifetime
/// ends. In `.stack`, toasts pile up instead.
///
/// `@MainActor`-isolated because it's a UI-bound ViewModel driven by
/// SwiftUI: the auto-dismiss `Task` below inherits this actor from its
/// creation context, so it can call back into `self` after `Task.sleep`
/// without an explicit `MainActor.run` hop.
@Observable
@MainActor
public final class KitoToastCenter: KitoViewModel {
    /// The front-most toast.
    public private(set) var current: KitoToast?
    /// Everything on screen, newest first.
    public private(set) var visible: [KitoToast] = []
    public var position: KitoToastPosition
    public var presentation: KitoToastPresentation
    /// A stack fanned out to show every toast; auto-dismissal pauses while it is.
    public var isStackExpanded = false {
        didSet {
            guard oldValue != isStackExpanded else { return }
            isStackExpanded ? pauseTimers() : resumeTimers()
        }
    }
    private var queue: [KitoToast] = []
    private var dismissTasks: [UUID: Task<Void, Never>] = [:]

    public init(position: KitoToastPosition = .top, presentation: KitoToastPresentation = .single) {
        self.position = position
        self.presentation = presentation
    }

    var maxVisible: Int {
        switch presentation {
        case .single: return 1
        case .stack(let maxVisible): return max(maxVisible, 1)
        }
    }

    public func show(_ toast: KitoToast) {
        switch presentation {
        case .single:
            queue.append(toast)
            if visible.isEmpty { advance() }
        case .stack:
            visible.insert(toast, at: 0)
            while visible.count > maxVisible {
                let dropped = visible.removeLast()
                cancelTimer(dropped.id)
            }
            schedule(toast)
            sync()
        }
    }

    public func show(_ message: String, style: KitoToastStyle = .info, duration: TimeInterval? = 3) {
        show(KitoToast(message: message, style: style, duration: duration))
    }

    public func dismissCurrent() {
        guard let current else { return }
        dismiss(id: current.id)
    }

    /// Dismisses one toast, wherever it is in the stack or queue.
    public func dismiss(id: UUID) {
        cancelTimer(id)
        queue.removeAll { $0.id == id }
        visible.removeAll { $0.id == id }
        if visible.count <= 1 { isStackExpanded = false }
        sync()
        advance()
    }

    /// Clears the screen and the queue.
    public func dismissAll() {
        dismissTasks.values.forEach { $0.cancel() }
        dismissTasks = [:]
        queue = []
        visible = []
        isStackExpanded = false
        sync()
    }

    /// Advances a progress toast's fill in place — the same toast slot
    /// keeps animating rather than being replaced, which is what makes the
    /// bar read as one continuous upload instead of a flicker of new toasts.
    /// A no-op if `id` is no longer on screen or queued.
    public func updateProgress(id: UUID, fraction: Double) {
        mutate(id) { $0.progress = KitoToastProgress(fraction: fraction) }
    }

    /// Morphs a progress or loading toast into a normal success/error/etc.
    /// state — same toast, same slot, no dismiss-then-requeue flicker. Ends
    /// the "in progress, can't auto-dismiss" hold: the resulting toast
    /// follows `duration` (`3` seconds by default) like any other.
    public func complete(id: UUID, style: KitoToastStyle, title: String? = nil, message: String? = nil, duration: TimeInterval? = 3) {
        let found = mutate(id) { toast in
            toast.progress = nil
            toast.isLoading = false
            toast.style = style
            if let title { toast.title = title }
            if let message { toast.message = message }
            toast.duration = duration
        }
        guard found, let toast = visible.first(where: { $0.id == id }) else { return }
        schedule(toast)
    }

    /// Shows a loading toast while `operation` runs, then turns it into a success or error
    /// toast. Returns the operation's result, or rethrows its error.
    @discardableResult
    public func promise<T>(loading: String, success: String, failure: String? = nil, layout: KitoToastLayout = .card,
                           operation: () async throws -> T) async throws -> T {
        let toast = KitoToast(message: loading, layout: layout, isLoading: true)
        show(toast)
        do {
            let value = try await operation()
            complete(id: toast.id, style: .success, message: success)
            return value
        } catch {
            complete(id: toast.id, style: .error, message: failure ?? error.localizedDescription)
            throw error
        }
    }

    // MARK: Internals

    private func advance() {
        guard case .single = presentation, visible.isEmpty, !queue.isEmpty else { return }
        let next = queue.removeFirst()
        visible = [next]
        sync()
        schedule(next)
    }

    private func sync() {
        current = visible.first
    }

    @discardableResult
    private func mutate(_ id: UUID, _ change: (inout KitoToast) -> Void) -> Bool {
        if let index = visible.firstIndex(where: { $0.id == id }) {
            change(&visible[index])
            sync()
            return true
        }
        if let index = queue.firstIndex(where: { $0.id == id }) {
            change(&queue[index])
            return true
        }
        return false
    }

    private func schedule(_ toast: KitoToast) {
        cancelTimer(toast.id)
        guard let duration = toast.duration, !isStackExpanded else { return }
        let id = toast.id
        dismissTasks[id] = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            guard !Task.isCancelled else { return }
            self?.dismiss(id: id)
        }
    }

    private func cancelTimer(_ id: UUID) {
        dismissTasks[id]?.cancel()
        dismissTasks[id] = nil
    }

    private func pauseTimers() {
        dismissTasks.values.forEach { $0.cancel() }
        dismissTasks = [:]
    }

    private func resumeTimers() {
        visible.forEach(schedule)
    }
}
