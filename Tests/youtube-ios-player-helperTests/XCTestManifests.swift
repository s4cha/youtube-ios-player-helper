import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(youtube_ios_player_helperTests.allTests),
    ]
}
#endif
