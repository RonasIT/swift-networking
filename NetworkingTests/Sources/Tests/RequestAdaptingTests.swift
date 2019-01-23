//
// Created by Nikita Zatsepilov on 2019-01-18.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

import XCTest
import Networking
import Alamofire

private struct CustomHeader: RequestHeader {
    let key: String
    let value: String
}

final class RequestAdaptingTests: XCTestCase {

    private var request: CancellableRequest?

    private lazy var requestAdapter: MockRequestAdapter = .init()
    private lazy var errorHandler: MockErrorHandler = .init()
    private lazy var networkService: NetworkService = {
        let requestAdaptingService = RequestAdaptingService(requestAdapters: [requestAdapter])
        let errorHandlingService = ErrorHandlingService(errorHandlers: [errorHandler])
        let networkService = MockNetworkService(requestAdaptingService: requestAdaptingService,
                                                errorHandlingService: errorHandlingService)
        return networkService
    }()

    override func tearDown() {
        super.tearDown()
        request = nil
        requestAdapter.adapting = nil
        errorHandler.errorHandling = nil
    }
    
    func testCustomHeaderAppending() {
        let customHeader = CustomHeader(key: "Header", value: "Value")
        requestAdapter.adapting = { request in
            request.appendHeader(customHeader)
            request.appendHeader(customHeader)
            request.appendHeader(customHeader)
            XCTAssertEqual(request.headers.count, 1)
        }

        let successExpectation = expectation(description: "Custom header received back")
        successExpectation.assertForOverFulfill = true

        let endpoint = MockEndpoint.headersValidation([customHeader])
        request = networkService.request(for: endpoint, success: {
            successExpectation.fulfill()
        }, failure: { _ in
            XCTFail("Invalid case")
        })

        wait(for: [successExpectation], timeout: 10)
    }

    func testRequestAdaptingOnRetry() {
        let requestAdaptedOnRetryExpectation = expectation(description: "Expecting request adapting on retry")
        requestAdaptedOnRetryExpectation.expectedFulfillmentCount = 2

        requestAdapter.adapting = { request in
            requestAdaptedOnRetryExpectation.fulfill()
        }
        errorHandler.errorHandling = { error, completion in
            completion(.retryNeeded)
        }
        request = networkService.request(for: MockEndpoint.failure, success: {
            print("test")
        }, failure: { _ in
            print("test")
        })

        wait(for: [requestAdaptedOnRetryExpectation], timeout: 10)
    }
}
