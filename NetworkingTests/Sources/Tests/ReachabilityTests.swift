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
        let unsubcriptionExpectation = expectation(description: "Expecting unsubscribeHandler called")
        unsubcriptionExpectation.assertForOverFulfill = true

        // Without wrapper closure will capture copy of original id
        // To validate id we wrap string id to the class and provide id from same reference
        final class WrappedId {
            var id: String = ""
        }

        let wrappedId = WrappedId()
        let subscription = NetworkReachabilitySubscription(unsubscribeHandler: { id in
            XCTAssertEqual(id, wrappedId.id)
            unsubcriptionExpectation.fulfill()
        }, notificationHandler: { isReachable in
            XCTAssertEqual(isReachable, true)
            notificationExpectation.fulfill()
        })

        wrappedId.id = subscription.id
        subscription.notificationHandler(true)
        subscription.unsubscribe()
        
        wait(for: [notificationExpectation, unsubcriptionExpectation], timeout: 3, enforceOrder: true)
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
}
