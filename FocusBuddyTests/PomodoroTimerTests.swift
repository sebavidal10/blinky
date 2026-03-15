import XCTest
@testable import FocusBuddy

final class PomodoroTimerTests: XCTestCase {
    var timer: PomodoroTimer!

    override func setUp() {
        super.setUp()
        timer = PomodoroTimer.shared
        timer.reset()
        // Reset durations for consistent testing
        timer.workDuration = 60
        timer.shortBreakDuration = 60
        timer.longBreakDuration = 60
        timer.sessionsUntilLongBreak = 2
        timer.completedSessions = 0
    }

    func testInitialState() {
        XCTAssertEqual(timer.phase, .idle)
        XCTAssertEqual(timer.isRunning, false)
        XCTAssertEqual(timer.secondsRemaining, 60)
    }

    func testStartTimer() {
        timer.start()
        XCTAssertEqual(timer.phase, .working)
        XCTAssertTrue(timer.isRunning)
    }

    func testWorkingToBreakTransition() {
        timer.start()
        XCTAssertEqual(timer.phase, .working)
        
        // Simulate timer ending
        timer.secondsRemaining = 0
        // We need to call the internal tick or advancePhase. 
        // Since advancePhase is private, we'll use a hack or assume we are testing the logic via public methods if possible.
        // For the sake of this test, let's assume we can trigger the transition.
        // In a real scenario, we might want to make advancePhase internal for testing.
        
        // Let's use skip() which calls advancePhase() internally
        timer.skip()
        
        XCTAssertEqual(timer.phase, .breakTime)
        XCTAssertEqual(timer.completedSessions, 1)
    }

    func testLongBreakTransition() {
        timer.sessionsUntilLongBreak = 2
        
        timer.start()
        timer.skip() // Transition to breakTime (session 1)
        XCTAssertEqual(timer.phase, .breakTime)
        
        timer.skip() // Transition to working
        XCTAssertEqual(timer.phase, .working)
        
        timer.skip() // Transition to longBreak (session 2)
        XCTAssertEqual(timer.phase, .longBreak)
        XCTAssertEqual(timer.completedSessions, 2)
    }
    
    func testDurationValidation() {
        timer.workDuration = 10
        XCTAssertEqual(timer.workDuration, 60, "Duration should be at least 60 seconds")
    }
}
