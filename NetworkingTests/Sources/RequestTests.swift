//
// Created by Nikita Zatsepilov on 2019-01-19.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

import Networking
import Alamofire
import XCTest

final class RequestTests: XCTestCase {

    var request: CancellableRequest?

    private lazy var errorHandler: MockErrorHandler = .init()
    private lazy var networkService: NetworkService = {
        let errorHandlingService = ErrorHandlingService(errorHandlers: [errorHandler])
        return NetworkService(errorHandlingService: errorHandlingService)
    }()

    override func tearDown() {
        super.tearDown()
        request = nil
        errorHandler.errorHandling = nil
        errorHandler.canHandleError = nil
    }

    func testCancellation() {
        let responseExpectation = expectation(description: "Expecting cancellation error in response")
        responseExpectation.assertForOverFulfill = true

        request = networkService.request(for: HTTPBinEndpoint.delay(0), success: {
            XCTFail("Invalid case")
        }, failure: { error in
            XCTAssertTrue((error as NSError).code == NSURLErrorCancelled)
            responseExpectation.fulfill()
        })
        request?.cancel()

        wait(for: [responseExpectation], timeout: 10)
    }
    
    func testUploadCancellation() {
        let responseExpectation = expectation(description: "Expecting cancellation error in response")
        responseExpectation.assertForOverFulfill = true
        
        request = networkService.uploadRequest(for: HTTPBinEndpoint.upload, success: {
            XCTFail("Invalid case")
        }, failure: { error in
            XCTAssertTrue((error as NSError).code == NSURLErrorCancelled)
            responseExpectation.fulfill()
        })
        request?.cancel()

        wait(for: [responseExpectation], timeout: 10)
    }

    func testRequestMemoryLeak() {
        let lifecycleExpectation = expectation(description: "Expecting request callbacks are not called")
        
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
