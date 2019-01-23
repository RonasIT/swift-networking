//
// Created by Nikita Zatsepilov on 2019-01-18.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

import XCTest
import Networking
import Alamofire

final class TokenRefreshingTests: XCTestCase {

    private lazy var sessionService: MockSessionService = {
        return MockSessionService()
    }()

    private lazy var errorHandlingService: ErrorHandlingServiceProtocol = {
        return ErrorHandlingService(errorHandlers: [
            UnauthorizedErrorHandler(sessionService: sessionService)
        ])
    }()

    private lazy var requestAdaptingService: RequestAdaptingServiceProtocol = {
        return RequestAdaptingService(requestAdapters: [
            TokenRequestAdapter(sessionService: sessionService)
        ])
    }()

    private lazy var networkService: NetworkService = {
        return MockNetworkService(requestAdaptingService: requestAdaptingService,
                                  errorHandlingService: errorHandlingService)
    }()
    
    private var requests: [CancellableRequest] = []

    override func tearDown() {
        super.tearDown()
        requests = []
        sessionService.clearToken()
    }

    func testTokenRefreshingWithSuccess() {
        let tokenRefreshingStartedExpectation = expectation(description: "Expecting token refreshing")
        tokenRefreshingStartedExpectation.assertForOverFulfill = true

        let successResponseExpectation = expectation(description: "Expecting success in response")
        successResponseExpectation.assertForOverFulfill = true
        successResponseExpectation.expectedFulfillmentCount = 3

        let newToken = MockSessionService.Constants.validToken
        sessionService.tokenRefreshHandler = { success, _ in
            tokenRefreshingStartedExpectation.fulfill()
            success?(newToken)
        }

        for _ in 0..<successResponseExpectation.expectedFulfillmentCount {
            let request = networkService.request(for: MockEndpoint.authorized, success: {
                successResponseExpectation.fulfill()
            }, failure: { error in
                XCTFail("Invalid case")
            })
            requests.append(request)
        }

        let expectations = [tokenRefreshingStartedExpectation, successResponseExpectation]
        wait(for: expectations, timeout: 10, enforceOrder: true)
    }

    func testTokenRefreshingWithFailure() {
        let tokenRefreshingStartedExpectation = expectation(description: "Expecting token refresh")
        tokenRefreshingStartedExpectation.assertForOverFulfill = true
        
        let failureResponseExpectation = expectation(description: "Expecting failure in response")
        failureResponseExpectation.assertForOverFulfill = true
        failureResponseExpectation.expectedFulfillmentCount = 5

        let tokenRefreshError = MockError()
        sessionService.tokenRefreshHandler = { _, failure in
            tokenRefreshingStartedExpectation.fulfill()
            failure?(tokenRefreshError)
        }
        
        for _ in 0..<failureResponseExpectation.expectedFulfillmentCount {
            let request = networkService.request(for: MockEndpoint.authorized, success: {
                XCTFail("Invalid case")
            }, failure: { error in
                if let error = error as? MockError {
                    XCTAssertFalse(error === tokenRefreshError, "Request shouldn't fail with error of token refreshing")
                }
                failureResponseExpectation.fulfill()
            })
            requests.append(request)
        }

        let expectations = [tokenRefreshingStartedExpectation, failureResponseExpectation]
        wait(for: expectations, timeout: 10, enforceOrder: true)
    }
}
