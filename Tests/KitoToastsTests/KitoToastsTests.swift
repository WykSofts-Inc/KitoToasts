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
}
