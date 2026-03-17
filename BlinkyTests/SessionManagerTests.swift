import XCTest
@testable import Blinky

final class SessionManagerTests: XCTestCase {
    var timer: SessionManager!
    private var cancellables = Set<AnyCancellable>()

    override func setUp() {
        super.setUp()
        timer = SessionManager.shared
        timer.reset()
    }

    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

    func testInitialState() {
        XCTAssertEqual(timer.phase, .idle)
        XCTAssertEqual(timer.isRunning, false)
        XCTAssertEqual(timer.secondsElapsed, 0)
        XCTAssertEqual(timer.isInfiniteSession, true)
    }

    func testStartInfiniteSession() {
        timer.currentGoal = "Test Task"
        timer.start()
        
        XCTAssertEqual(timer.phase, .working)
        XCTAssertEqual(timer.isRunning, true)
        XCTAssertEqual(timer.isInfiniteSession, true)
    }

    func testStartMeetingSession() {
        timer.sessionDurationLimit = 1800 // 30 minutes
        timer.currentGoal = "Team Standup"
        timer.start()
        
        XCTAssertEqual(timer.phase, .meeting)
        XCTAssertEqual(timer.isRunning, true)
        XCTAssertEqual(timer.isInfiniteSession, false)
        XCTAssertEqual(timer.secondsRemaining, 1800)
    }

    func testPauseResume() {
        timer.start()
        XCTAssertTrue(timer.isRunning)
        
        timer.stop()
        XCTAssertFalse(timer.isRunning)
        
        timer.start()
        XCTAssertTrue(timer.isRunning)
    }

    func testReset() {
        timer.start()
        timer.secondsElapsed = 300
        
        timer.reset()
        
        XCTAssertEqual(timer.phase, .idle)
        XCTAssertEqual(timer.isRunning, false)
        XCTAssertEqual(timer.secondsElapsed, 0)
        XCTAssertEqual(timer.secondsRemaining, 0)
    }

    func testFinishSession() {
        timer.start()
        timer.secondsElapsed = 600 // 10 minutes
        
        let initialTodayCount = timer.totalSessionsToday
        let initialHistoryCount = timer.sessionsHistory.count
        
        timer.finishSession()
        
        XCTAssertEqual(timer.totalSessionsToday, initialTodayCount + 1)
        XCTAssertEqual(timer.sessionsHistory.count, initialHistoryCount + 1)
        XCTAssertEqual(timer.phase, .idle)
    }

    func testTimeStringFormat() {
        timer.secondsElapsed = 125 // 2:05
        XCTAssertEqual(timer.timeString, "02:05")
        
        timer.secondsElapsed = 3665 // 61:05
        XCTAssertEqual(timer.timeString, "61:05")
    }

    func testProgressCalculation() {
        timer.sessionDurationLimit = 100
        timer.secondsElapsed = 50
        
        XCTAssertEqual(timer.progress, 0.5)
    }

    func testProgressReturnsZeroForInfiniteSession() {
        timer.secondsElapsed = 100
        XCTAssertEqual(timer.progress, 0)
    }

    func testDayResetLogic() {
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
        
        UserDefaults.standard.set(yesterday, forKey: "lastActiveDate")
        
        timer.checkDayReset()
        
        XCTAssertEqual(timer.totalSessionsToday, 0)
    }

    func testStreakIncrementOnNewDay() {
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
        
        UserDefaults.standard.set(yesterday, forKey: "lastActiveDate")
        timer.totalSessionsToday = 5
        
        timer.checkDayReset()
        
        XCTAssertEqual(timer.currentStreak, 1)
    }

    func testMoodUpdatesOnStart() {
        XCTAssertEqual(timer.mood, .idle)
        
        timer.start()
        
        XCTAssertEqual(timer.mood, .focused)
    }

    func testMoodUpdatesOnStop() {
        timer.start()
        XCTAssertEqual(timer.mood, .focused)
        
        timer.stop()
        
        XCTAssertEqual(timer.mood, .idle)
    }
}