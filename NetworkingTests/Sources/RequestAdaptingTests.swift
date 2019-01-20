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
        let networkService = NetworkService(requestAdaptingService: requestAdaptingService,
                                            errorHandlingService: errorHandlingService)
        return networkService
    }()

    override func tearDown() {
        super.tearDown()
        request = nil
        requestAdapter.adapting = nil
        errorHandler.canHandleError = nil
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

        let headerReceivedBackExpectation = expectation(description: "Custom header received back")
        headerReceivedBackExpectation.assertForOverFulfill = true
        
        request = networkService.request(for: HTTPBinEndpoint.anythingJSON([:]), success: { (json: [String: Any]) in
            guard let headers = json["headers"] as? [String: String] else {
                XCTFail("Invalid response")
                return
            }

            let headerOrNil = headers.first { header in
                // Headers can change string case
                return header.key.caseInsensitiveCompare(customHeader.key) == .orderedSame
            }

            guard let header = headerOrNil,
                  // Values can change string case
                  header.value.caseInsensitiveCompare(customHeader.value) == .orderedSame else {
                XCTFail("Header not found")
                return
            }

            headerReceivedBackExpectation.fulfill()
        }, failure: { _ in
            XCTFail("Invalid case")
        })

        wait(for: [headerReceivedBackExpectation], timeout: 10)
    }

    func testRequestAdaptingOnRetry() {
        let requestAdaptedOnRetryExpectation = expectation(description: "Expecting request adapting on retry")
        requestAdaptedOnRetryExpectation.expectedFulfillmentCount = 2

        requestAdapter.adapting = { request in
            requestAdaptedOnRetryExpectation.fulfill()
        }
        errorHandler.canHandleError = { _ in
            return true
        }
        errorHandler.errorHandling = { error, completion in
            completion(.retryNeeded)
        }
        request = networkService.request(for: HTTPBinEndpoint.status(404), success: {
            print("test")
        }, failure: { _ in
            print("test")
        })

        wait(for: [requestAdaptedOnRetryExpectation], timeout: 999)
    }
}
