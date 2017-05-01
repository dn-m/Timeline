//
//  TimelineTests.swift
//  Timeline
//
//  Created by James Bean on 6/23/16.
//
//

import XCTest
import Collections
import ArithmeticTools
@testable import Timeline

class TimelineTests: XCTestCase {
    
    // Current time in nanoseconds (convert to Double then divide by 1_000_000_000)
    var now: UInt64 {
        return DispatchTime.now().uptimeNanoseconds
    }
    
    var nowSeconds: Seconds {
        return Double(now) / 1_000_000_000
    }

    func testTimeStampToFrame() {
        
        let body: ActionBody = { print("something") }
        let timeStamp: Seconds = 0.5
        
        let timeline = Timeline(rate: 1/60)
        timeline.add(at: timeStamp, body: body)
        
        XCTAssertEqual(timeline.count, 1)
        XCTAssertNotNil(timeline[Frames(30)])
    }
    
    func testDefaultInitAtOneOverSixty() {
        
        let body: ActionBody = { print("something") }
        let timeStamp: Seconds = 0.5
        
        let timeline = Timeline()
        timeline.add(at: timeStamp, body: body)
        
        XCTAssertEqual(timeline.count, 1)
        XCTAssertNotNil(timeline[Frames(60)])
    }
    
    func testMetronomeInjection() {
        
        let timeline = Timeline()
        stride(from: Seconds(0), to: 10, by: 0.25).forEach { timeline.add(at: $0) { () } }
        
        XCTAssertEqual(timeline.count, 40)
    }
    
    func testCurrentFrameInitZero() {
        let timeline = Timeline()
        XCTAssertEqual(timeline.currentFrame, 0)
    }

    func testIterationSorted() {
        
        let timeline = Timeline()
        timeline.add(at: 3) { () }
        timeline.add(at: 2) { () }
        timeline.add(at: 5) { () }
        timeline.add(at: 1) { () }
        timeline.add(at: 4) { () }
        
        XCTAssertEqual(
            timeline.map { $0.0 },
            [1,2,3,4,5].map { Frames(Seconds($0) / timeline.rate) }
        )
    }
    
    func testClear() {
        
        let timeline = Timeline()
        timeline.add(at: 3) { () }
        timeline.add(at: 2) { () }
        timeline.clear()
        
        XCTAssertEqual(timeline.count, 0)
    }
    
    func testStart() {
        
        let timeline = Timeline()
        timeline.add(at: 3) { () }
        timeline.add(at: 2) { () }
        
        XCTAssertFalse(timeline.isActive)

        timeline.start()
        
        XCTAssert(timeline.isActive)
    }
    
    func testStop() {
        
        let timeline = Timeline()
        timeline.add(at: 3) { () }
        timeline.add(at: 2) { () }
        timeline.start()
        timeline.stop()
        
        XCTAssertFalse(timeline.isActive)
        XCTAssertEqual(timeline.currentFrame, 0)
    }
    
    func testSubscriptSeconds() {
        
        let timeline = Timeline()
        timeline.add(at: 3) { () }
        timeline.add(at: 2) { () }
        timeline.add(at: 5) { () }
        timeline.add(at: 1) { () }
        timeline.add(at: 4) { () }
        
        stride(from: Seconds(1), to: 5, by: 1).forEach { timeStamp in
            XCTAssertNotNil(timeline[timeStamp])
        }
    }
    
    // TODO: Implement: testAccuracyWithTimePoints([Seconds]) { }
    
    func assertAccuracyWithRepeatedPulse(interval: Seconds, for duration: Seconds) {
     
        guard duration > 0 else { return }
        
        let unfulfilledExpectation = expectation(description: "Test accuracy of Timer")
        
        let range = stride(from: Seconds(0), to: duration, by: interval).map { $0 }
        
        // Data
        var globalErrors: [Double] = []
        var localErrors: [Double] = []
        
        // Create `Timeline` to test
        let timeline = Timeline(rate: 1/120)
        
        let start: UInt64 = DispatchTime.now().uptimeNanoseconds
        var last: UInt64 = DispatchTime.now().uptimeNanoseconds
        
        for (i, offset) in range.enumerated() {
            
            timeline.add(at: offset) {
                
                // For now, don't test an event on first hit, as the offset should be 0
                if offset > 0 {
                    
                    let current = DispatchTime.now().uptimeNanoseconds
                    
                    let actualTotalOffset = Seconds(current - start) / 1_000_000_000
                    let expectedTotalOffset = range[i]
                    
                    let actualLocalOffset = Seconds(current - last) / 1_000_000_000
                    let expectedLocalOffset: Seconds = interval
                    
                    let globalError = abs(actualTotalOffset - expectedTotalOffset)
                    let localError = abs(expectedLocalOffset - actualLocalOffset)

                    globalErrors.append(globalError)
                    localErrors.append(localError)
                    
                    last = current
                }
            }
        }
        
        // Finish up 1 second after done
        timeline.add(at: range.last! + 1) {
            
            let maxGlobalError = globalErrors.max()!
            let averageGlobalError = globalErrors.mean!
            
            let maxLocalError = localErrors.max()!
            let averageLocalError = localErrors.mean!
            
            XCTAssertLessThan(maxGlobalError, 0.015)
            XCTAssertLessThan(averageGlobalError, 0.015)
            
            XCTAssertLessThan(maxLocalError, 0.015)
            XCTAssertLessThan(averageLocalError, 0.015)
            
            // Fulfill expecation
            unfulfilledExpectation.fulfill()
        }
        
        // Start the timeline
        timeline.start()
        
        // Ensure that test lasts for enough time
        waitForExpectations(timeout: duration + 2) { _ in }
    }
    
    
    func assertAccuracyWithPulseEverySecond(for duration: Seconds) {
        assertAccuracyWithRepeatedPulse(interval: 1, for: duration)
    }
    
    func testAccuractWithFastPulseForFiveSeconds() {
        assertAccuracyWithRepeatedPulse(interval: 0.1, for: 5)
    }
    
    /*
    func testAccuracyWithPulseEverySecondForAMinute() {
        assertAccuracyWithPulseEverySecond(for: 60)
    }
    
    func testAccuracyWithPulseEveryThirdOfASecondForAMinute() {
        assertAccuracyWithRepeatedPulse(interval: 1/3, for: 60)
    }
    
    func testAccuracyWithPulseEveryTenthOfASecondForAMinute() {
        assertAccuracyWithRepeatedPulse(interval: 1/10, for: 60)
    }
    
    func testAccuracyWithPulseAbritraryIntervalForAMinute() {
        assertAccuracyWithRepeatedPulse(interval: 0.123456, for: 60)
    }
    
    func testAccuracyOfLongIntervalForAMinute() {
        assertAccuracyWithRepeatedPulse(interval: 12.3456, for: 60)
    }
    
    func testAccuracyWithPuleEverySecondFor30Minutes() {
        assertAccuracyWithPulseEverySecond(for: 60)
    }
     */
    
    func testAccuracyWithPulseEverySecondForFiveSeconds() {
        assertAccuracyWithRepeatedPulse(interval: 1, for: 5)
    }
}
