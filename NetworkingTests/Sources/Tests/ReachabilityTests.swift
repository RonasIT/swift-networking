//
// Created by Nikita Zatsepilov on 2019-01-27.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

@testable import Networking
import XCTest
import Alamofire

final class ReachabilityTests: XCTestCase {

    func testReachabilitySubscription() {
        let notificationExpectation = expectation(description: "Expecting notificationHandler notified")
        notificationExpectation.assertForOverFulfill = true
        let unsubscriptionExpectation = expectation(description: "Expecting unsubscribeHandler called")
        unsubscriptionExpectation.assertForOverFulfill = true

        var expectedId = ""
        let subscription = NetworkReachabilitySubscription(unsubscribeHandler: { id in
            XCTAssertEqual(id, expectedId)
            unsubscriptionExpectation.fulfill()
        }, notificationHandler: { isReachable in
            XCTAssertEqual(isReachable, true)
            notificationExpectation.fulfill()
        })

        expectedId = subscription.id
        subscription.notificationHandler(true)
        subscription.unsubscribe()

        wait(for: [notificationExpectation, unsubscriptionExpectation], timeout: 3, enforceOrder: true)
    }

    func testReachabilitySubscriptionMemoryLeaks() {
        var subscription: NetworkReachabilitySubscription? = NetworkReachabilitySubscription(unsubscribeHandler: { _ in },
                                                                                             notificationHandler: { _ in })
        weak var weakSubscription = subscription
        subscription?.notificationHandler(true)
        subscription?.unsubscribe()
        subscription = nil

        XCTAssertNil(weakSubscription)
    }

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
            return reachabilityService.subscribe { isReachable in
                XCTAssertEqual(isReachable, networkListener.isReachable)
                notificationReceivedExpectation.fulfill()
            }
        }

        for _ in 0..<numberOfReachabilityChanges {
            networkListener.isReachable.toggle()
        }

        wait(for: [notificationReceivedExpectation], timeout: 5)

        subscriptions.forEach { $0.unsubscribe() }
        reachabilityService.stopMonitoring()
    }
}
