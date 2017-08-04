import XCTest
import KurioPuree

class LoggerTagPatternMatchingTest: XCTestCase {
    func testTagPatternMatching() {
        XCTAssertTrue(Logger.matchesTag("aaa", pattern: "aaa").isMatched)
        XCTAssertFalse(Logger.matchesTag("aaa", pattern: "bbb").isMatched)
        XCTAssertTrue(Logger.matchesTag("aaa", pattern: "*").isMatched)
        XCTAssertTrue(Logger.matchesTag("bbb", pattern: "*").isMatched)
        XCTAssertFalse(Logger.matchesTag("aaa.bbb", pattern: "*").isMatched)
        XCTAssertTrue(Logger.matchesTag("aaa.bbb", pattern: "aaa.bbb").isMatched)
        XCTAssertTrue(Logger.matchesTag("aaa.bbb", pattern: "aaa.*").isMatched)
        XCTAssertTrue(Logger.matchesTag("aaa.ccc", pattern: "aaa.*").isMatched)
        XCTAssertFalse(Logger.matchesTag("aaa.bbb.ccc", pattern: "aaa.*").isMatched)
        XCTAssertFalse(Logger.matchesTag("aaa.bbb.ccc", pattern: "aaa.*.ccc").isMatched) // deny intermediate wildcard
        XCTAssertFalse(Logger.matchesTag("aaa.ccc.ddd", pattern: "aaa.*.ccc").isMatched)

        XCTAssertTrue(Logger.matchesTag("a", pattern: "a.**").isMatched)
        XCTAssertTrue(Logger.matchesTag("a.b", pattern: "a.**").isMatched)
        XCTAssertTrue(Logger.matchesTag("a.b.c", pattern: "a.**").isMatched)
        XCTAssertFalse(Logger.matchesTag("b.c", pattern: "a.**").isMatched)
    }

    func testCapturingWildcard() {
        XCTAssertEqual(Logger.matchesTag("aaa.bbb", pattern: "aaa.*").capturedString, "bbb")
        XCTAssertEqual(Logger.matchesTag("aaa.ccc", pattern: "aaa.*").capturedString, "ccc")

        XCTAssertEqual(Logger.matchesTag("a", pattern: "a.**").capturedString, "")
        XCTAssertEqual(Logger.matchesTag("a.b", pattern: "a.**").capturedString, "b")
        XCTAssertEqual(Logger.matchesTag("a.b.c", pattern: "a.**").capturedString, "b.c")
        XCTAssertNil(Logger.matchesTag("b.c", pattern: "a.**").capturedString)
    }
}
