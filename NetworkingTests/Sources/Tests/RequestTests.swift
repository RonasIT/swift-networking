//
// Created by Nikita Zatsepilov on 2019-01-19.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

import Networking
import Alamofire
import XCTest

final class RequestTests: XCTestCase {

    var request: CancellableRequest?

    override func tearDown() {
        super.tearDown()
        request = nil
    }

    func testCancellation() {
        let responseExpectation = expectation(description: "Expecting cancellation error in response")
        responseExpectation.assertForOverFulfill = true

        // We have to test implementation of real request
        let errorHandlingService = ErrorHandlingService()
        let networkService = NetworkService(errorHandlingService: errorHandlingService)
        request = networkService.request(for: HTTPBinEndpoint.status(200), success: {
            XCTFail("Invalid case")
        }, failure: { error in
            switch error {
            case let error as GeneralRequestError where error == .cancelled:
                responseExpectation.fulfill()
            default:
                XCTFail("Invalid error")
            }
        })
        request?.cancel()

        wait(for: [responseExpectation], timeout: 10)
    }
    
    func testUploadCancellation() {
        let responseExpectation = expectation(description: "Expecting cancellation error in response")
        responseExpectation.assertForOverFulfill = true

        // We have to test implementation of real request
        let errorHandlingService = ErrorHandlingService()
        let networkService = NetworkService(errorHandlingService: errorHandlingService)
        request = networkService.uploadRequest(for: HTTPBinEndpoint.uploadStatus(200), success: {
            XCTFail("Invalid case")
        }, failure: { error in
            switch error {
            case let error as GeneralRequestError where error == .cancelled:
                responseExpectation.fulfill()
            default:
                XCTFail("Invalid error")
            }
        })
        request?.cancel()

        wait(for: [responseExpectation], timeout: 10)
    }

    func testRequestMemoryLeak() {
        let lifecycleExpectation = expectation(description: "Expecting request callbacks are not called")

        // We have to test implementation of real request
        let networkService = NetworkService()
        weak var request = networkService.request(for: HTTPBinEndpoint.status(200), success: {
            XCTFail("Invalid case")
        }, failure: { _ in
            XCTFail("Invalid case")
        })
        
        _ = XCTWaiter.wait(for: [lifecycleExpectation], timeout: 3)
        XCTAssertNil(request)
        lifecycleExpectation.fulfill()
    }
    
    func testUploadRequestMemoryLeak() {
        let lifecycleExpectation = expectation(description: "Expecting request callbacks are not called")

        // We have to test implementation of real request
        let networkService = NetworkService()
        weak var request = networkService.uploadRequest(for: HTTPBinEndpoint.status(200), success: {
            XCTFail("Invalid case")
        }, failure: { _ in
            XCTFail("Invalid case")
        })
        
        _ = XCTWaiter.wait(for: [lifecycleExpectation], timeout: 3)
        XCTAssertNil(request)
        lifecycleExpectation.fulfill()
    }
}
