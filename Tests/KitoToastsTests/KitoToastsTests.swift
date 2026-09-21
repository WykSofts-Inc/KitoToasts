//
//  KitoToastsTests.swift
//  KitoToasts
//
//  Created by Wycliff on 3/13/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import XCTest
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

    func testActionToastHasNilDuration() {
        let toast = KitoToast(message: "Undo?", action: KitoToastAction(title: "Undo") {})
        XCTAssertNil(toast.duration, "an actionable toast must not auto-dismiss")
    }

    func testDefaultPositionIsTop() {
        XCTAssertEqual(KitoToastCenter().position, .top)
    }

    func testBottomPositionHonored() {
        XCTAssertEqual(KitoToastCenter(position: .bottom).position, .bottom)
    }
}
