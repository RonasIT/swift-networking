//
// Created by Nikita Zatsepilov on 2019-01-27.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

@testable import Networking
import XCTest
import Alamofire
import Combine

final class ReachabilityTests: XCTestCase {

    func testReachabilityServiceIsReachableStatus() {
        let networkListener = MockNetworkListener()
        networkListener.isReachable = true

        let reachabilityService = ReachabilityService(networkListener: networkListener)
        reachabilityService.startMonitoring()
        XCTAssertTrue(reachabilityService.isReachable)

        networkListener.isReachable = false
        XCTAssertFalse(reachabilityService.isReachable)

        networkListener.isReachable = true
        XCTAssertTrue(reachabilityService.isReachable)
    }

    func testReachabilityServiceWithDefaultNetworkListener() {
        let reachabilityManager = NetworkReachabilityManager()!
        let listener: NetworkReachabilityManager.Listener = { status in }
        reachabilityManager.startListening(onUpdatePerforming: listener)

        // Will be initialized with real network listener
        let reachabilityService = ReachabilityService()
        reachabilityService.startMonitoring()

        XCTAssertEqual(reachabilityService.isReachable, reachabilityManager.isReachable)

        reachabilityManager.stopListening()
        reachabilityService.stopMonitoring()
    }

    func testReachabilityServiceNotifications() {
        let numberOfSubscribers = 5
        let numberOfReachabilityChanges = 3
        let numberOfNotifications = numberOfSubscribers * numberOfReachabilityChanges

        let notificationReceivedExpectation = expectation(description: "Expecting notification")
        notificationReceivedExpectation.expectedFulfillmentCount = numberOfNotifications
        notificationReceivedExpectation.assertForOverFulfill = true

        let networkListener = MockNetworkListener()
        networkListener.isReachable = true

        let reachabilityService = ReachabilityService(networkListener: networkListener)
        reachabilityService.startMonitoring()

        let subscriptions = (0..<numberOfSubscribers).map { _ in
            return reachabilityService.reachabilityStatusSubject.sink { (status: NetworkReachabilityManager.NetworkReachabilityStatus) in
                XCTAssertEqual(networkListener.isReachable, status.isReachable)
                notificationReceivedExpectation.fulfill()
            }
        }

        for _ in 0..<numberOfReachabilityChanges {
            networkListener.isReachable.toggle()
        }

        wait(for: [notificationReceivedExpectation], timeout: 5)

        subscriptions.forEach { (subscription: AnyCancellable) in
            subscription.cancel()
        }
        reachabilityService.stopMonitoring()
    }
}
