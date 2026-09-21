//
//  KitoToastsTests.swift
//  KitoToasts
//
//  Created by Wycliff on 3/13/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import XCTest
import SwiftUI
import KitoCore
@testable import KitoToasts

@MainActor
final class KitoToastsTests: XCTestCase {
    func testFirstToastShowsImmediately() {
        let center = KitoToastCenter()
        center.show("Saved", style: .success)
        XCTAssertEqual(center.current?.message, "Saved")
    }

    func testSecondToastQueuesUntilFirstDismissed() {
        let center = KitoToastCenter()
        center.show("First")
        center.show("Second")
        XCTAssertEqual(center.current?.message, "First")
        center.dismissCurrent()
        XCTAssertEqual(center.current?.message, "Second")
    }

    func testActionableToastHasNilDurationByDefault() {
        let toast = KitoToast(message: "Undo?", actions: [KitoToastAction(title: "Undo") {}])
        XCTAssertNil(toast.duration, "an actionable toast must not auto-dismiss")
    }

    func testMultipleActionsAreAllPreserved() {
        let toast = KitoToast(
            message: "Item deleted",
            actions: [
                KitoToastAction(title: "Undo", role: .primary) {},
                KitoToastAction(title: "View", role: .cancel) {},
            ]
        )
        XCTAssertEqual(toast.actions.count, 2)
        XCTAssertEqual(toast.actions[0].role, .primary)
        XCTAssertEqual(toast.actions[1].role, .cancel)
    }

    func testTitleIsOptionalMessageIsAlwaysPresent() {
        let plain = KitoToast(message: "Just a message")
        XCTAssertNil(plain.title)

        let withTitle = KitoToast(title: "Payment successful", message: "Order #1234 confirmed.")
        XCTAssertEqual(withTitle.title, "Payment successful")
    }

    func testIconDefaultsToAutomatic() {
        XCTAssertEqual(KitoToast(message: "x").icon, .automatic)
    }

    func testIconCanBeCustomOrHidden() {
        XCTAssertEqual(KitoToast(message: "x", icon: .custom("star.fill")).icon, .custom("star.fill"))
        XCTAssertEqual(KitoToast(message: "x", icon: .none).icon, .none)
    }

    func testExplicitDurationSurvivesEvenWithNoActions() {
        let toast = KitoToast(message: "x", duration: 5)
        XCTAssertEqual(toast.duration, 5)
    }

    func testAppearanceTitleFontSelectsCorrectSlot() {
        let large = Font.system(size: 99, weight: .black)
        let appearance = KitoToastAppearance(largeTitleFont: large)
        XCTAssertEqual(appearance.titleFont(for: .large), large)
        XCTAssertNotEqual(appearance.titleFont(for: .medium), large)
    }

    func testBackgroundStyleDefaultsToNilOnBothToastAndAppearance() {
        XCTAssertNil(KitoToast(message: "x").backgroundStyle)
        XCTAssertNil(KitoToastAppearance.default.backgroundStyle)
    }

    func testAppearanceCanSetADefaultBackgroundStyle() {
        let appearance = KitoToastAppearance(backgroundStyle: .color(.purple))
        guard case .color(let color) = appearance.backgroundStyle else {
            return XCTFail("expected .color(.purple)")
        }
        XCTAssertEqual(color, .purple)
    }

    func testPerToastBackgroundStyleIsPreserved() {
        let toast = KitoToast(message: "x", backgroundStyle: .gradient(.linear(.pink, .orange)))
        guard case .gradient(let gradient) = toast.backgroundStyle else {
            return XCTFail("expected .gradient")
        }
        XCTAssertEqual(gradient.colors, [.pink, .orange])
    }

    func testDefaultPositionIsTop() {
        XCTAssertEqual(KitoToastCenter().position, .top)
    }

    func testBottomPositionHonored() {
        XCTAssertEqual(KitoToastCenter(position: .bottom).position, .bottom)
    }

    func testProgressToastHasNilDurationByDefault() {
        let toast = KitoToast(message: "Uploading...", progress: KitoToastProgress(fraction: 0))
        XCTAssertNil(toast.duration, "a progress toast must not auto-dismiss while work is in flight")
    }

    func testProgressFractionClamps() {
        XCTAssertEqual(KitoToastProgress(fraction: 1.6).fraction, 1.0)
        XCTAssertEqual(KitoToastProgress(fraction: -0.3).fraction, 0.0)
    }

    func testUpdateProgressAdvancesTheCurrentToastInPlace() {
        let center = KitoToastCenter()
        center.show(KitoToast(message: "Uploading...", progress: KitoToastProgress(fraction: 0)))
        let id = center.current!.id

        center.updateProgress(id: id, fraction: 0.5)

        XCTAssertEqual(center.current?.id, id, "the same toast should still be current, not replaced")
        XCTAssertEqual(center.current?.progress?.fraction, 0.5)
    }

    func testUpdateProgressIgnoresStaleID() {
        let center = KitoToastCenter()
        center.show(KitoToast(message: "Uploading...", progress: KitoToastProgress(fraction: 0)))

        center.updateProgress(id: UUID(), fraction: 0.9)

        XCTAssertEqual(center.current?.progress?.fraction, 0, "an update for a toast that isn't current should be a no-op")
    }

    func testCompleteMorphsTheSameToastAndClearsProgress() {
        let center = KitoToastCenter()
        center.show(KitoToast(message: "Uploading...", progress: KitoToastProgress(fraction: 0.4)))
        let id = center.current!.id

        center.complete(id: id, style: .success, message: "Upload complete")

        XCTAssertEqual(center.current?.id, id, "completing should morph the same toast, not queue a new one")
        XCTAssertNil(center.current?.progress)
        XCTAssertEqual(center.current?.style, .success)
        XCTAssertEqual(center.current?.message, "Upload complete")
    }

    func testCompleteRestoresAutoDismissDuration() {
        let center = KitoToastCenter()
        center.show(KitoToast(message: "Uploading...", progress: KitoToastProgress(fraction: 0)))
        let id = center.current!.id

        center.complete(id: id, style: .success, duration: 2)

        XCTAssertEqual(center.current?.duration, 2, "once finished, the toast should be able to auto-dismiss again")
    }

    func testActionDefaultsToTitleOnlyContent() {
        let action = KitoToastAction(title: "Undo") {}
        XCTAssertEqual(action.content, .titleOnly)
        XCTAssertNil(action.icon)
    }

    func testActionCanCarryAnIconForIconOnlyOrCombinedLayouts() {
        let action = KitoToastAction(title: "Retry", icon: "arrow.clockwise", content: .iconAndTitle) {}
        XCTAssertEqual(action.icon, "arrow.clockwise")
        XCTAssertEqual(action.content, .iconAndTitle)
    }
}
