import SwiftUI
import XCTest
@testable import HermesMobile

/// `HermesHomeLayout.usesSplit` decides sidebar+detail vs one stack for a Hermes home.
/// Regular width alone is not enough: the iPhone Duo inner display is regular×regular at
/// about 626pt wide in portrait, too narrow for a 280pt sidebar beside a phone-width chat.
final class HermesHomeLayoutTests: XCTestCase {
    private let threshold = HermesHomeLayout.minimumSplitWidth

    func testCompactWidthNeverSplits() {
        XCTAssertFalse(HermesHomeLayout.usesSplit(isHome: true, horizontalSizeClass: .compact))
        XCTAssertFalse(HermesHomeLayout.usesSplit(isHome: true, horizontalSizeClass: .compact, containerWidth: 2000))
        XCTAssertFalse(HermesHomeLayout.usesSplit(isHome: true, horizontalSizeClass: nil, containerWidth: 2000))
    }

    func testPushedListNeverSplits() {
        XCTAssertFalse(HermesHomeLayout.usesSplit(isHome: false, horizontalSizeClass: .regular))
        XCTAssertFalse(HermesHomeLayout.usesSplit(isHome: false, horizontalSizeClass: .regular, containerWidth: 2000))
    }

    func testUnknownWidthFallsBackToSizeClass() {
        XCTAssertTrue(HermesHomeLayout.usesSplit(isHome: true, horizontalSizeClass: .regular))
        XCTAssertTrue(HermesHomeLayout.usesSplit(isHome: true, horizontalSizeClass: .regular, containerWidth: nil))
        XCTAssertTrue(HermesHomeLayout.usesSplit(isHome: true, horizontalSizeClass: .regular, containerWidth: 0),
                      "A zero width is 'not yet measured', not 'too narrow'")
    }

    func testRegularWidthSplitsAtOrAboveThreshold() {
        XCTAssertTrue(HermesHomeLayout.usesSplit(isHome: true, horizontalSizeClass: .regular, containerWidth: threshold))
        XCTAssertTrue(HermesHomeLayout.usesSplit(isHome: true, horizontalSizeClass: .regular, containerWidth: threshold + 1))
        // iPad mini portrait.
        XCTAssertTrue(HermesHomeLayout.usesSplit(isHome: true, horizontalSizeClass: .regular, containerWidth: 744))
        // iPhone Pro Max landscape.
        XCTAssertTrue(HermesHomeLayout.usesSplit(isHome: true, horizontalSizeClass: .regular, containerWidth: 956))
        // iPhone Duo inner display, landscape (derived ~890pt).
        XCTAssertTrue(HermesHomeLayout.usesSplit(isHome: true, horizontalSizeClass: .regular, containerWidth: 890))
    }

    func testRegularWidthStacksBelowThreshold() {
        XCTAssertFalse(HermesHomeLayout.usesSplit(isHome: true, horizontalSizeClass: .regular, containerWidth: threshold - 1))
        // iPhone Duo inner display, portrait (measured 1878×2670 native = 626×890pt).
        XCTAssertFalse(HermesHomeLayout.usesSplit(isHome: true, horizontalSizeClass: .regular, containerWidth: 626))
    }

    func testThresholdLeavesAPhoneWidthDetailBesideTheSidebar() {
        // Sessions sidebar minimum is 280 (HermesSessionListView's navigationSplitViewColumnWidth).
        let sidebarMinimum: CGFloat = 280
        XCTAssertGreaterThanOrEqual(threshold - sidebarMinimum, 393,
                                    "Detail column at the threshold must be at least an iPhone 16's 393pt")
    }

    func testHermesHomeDefaultsToUnknownWidth() {
        let avatar = SessionsHeader.Avatar(initials: "QA", color: .blue, foreground: .white,
            servers: .init(servers: [], activeServerID: nil), openSettings: {},
            switchToServer: { _ in }, addServer: {}, manageServers: {})
        let home = HermesHome(title: "t", avatar: avatar, tab: .constant(.sessions))
        XCTAssertNil(home.containerWidth)
    }
}
