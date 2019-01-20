//
// Created by Nikita Zatsepilov on 2019-01-18.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

import XCTest
import Networking
import Alamofire

final class ErrorHandlingTests: XCTestCase {

    private var request: CancellableRequest?

    private lazy var errorHandler: MockErrorHandler = .init()
    private lazy var networkService: NetworkService = {
        let errorHandlingService = ErrorHandlingService(errorHandlers: [errorHandler])
        return NetworkService(errorHandlingService: errorHandlingService)
    }()
    
    override func tearDown() {
        super.tearDown()
        request = nil
        errorHandler.canHandleError = nil
        errorHandler.errorHandling = nil
    }
    
    func testLifecycle() {
        let canHandleErrorExpectation = expectation(description: "Expecting `canHandleErrorHandler` call")
        canHandleErrorExpectation.assertForOverFulfill = true
        let errorHandlingExpectation = expectation(description: "Expecting `errorHandling` call")
        errorHandlingExpectation.assertForOverFulfill = true
        let requestFailureExpectation = expectation(description: "Expecting request failure")
        requestFailureExpectation.assertForOverFulfill = true
        
        errorHandler.canHandleError = { error in
            guard let responseCode = (error as? AFError)?.responseCode else {
                XCTFail("Invalid error")
                return false
            }
            XCTAssertEqual(responseCode, 404, "404 response code expected")
            canHandleErrorExpectation.fulfill()
            return true
        }
        errorHandler.errorHandling = { error, completion in
            errorHandlingExpectation.fulfill()
            completion(.continueFailure(with: error))
        }
        request = networkService.request(for: HTTPBinEndpoint.status(404), success: {
            XCTFail("Invalid case")
        }, failure: { error in
            requestFailureExpectation.fulfill()
        })
        
        let expectations = [canHandleErrorExpectation, errorHandlingExpectation, requestFailureExpectation]
        wait(for: expectations, timeout: 10, enforceOrder: true)
    }
    
    func testErrorHandlingShouldNotTriggered() {
        let requestFailedExpectation = expectation(description: "Expecting request failure")
        requestFailedExpectation.assertForOverFulfill = true

        errorHandler.canHandleError = { error in
            return false
        }
        errorHandler.errorHandling = { error, completion in
            XCTFail("Invalid case")
        }
        request = networkService.request(for: HTTPBinEndpoint.status(404), success: {
            XCTFail("Invalid case")
        }, failure: { _ in
            requestFailedExpectation.fulfill()
        })

        wait(for: [requestFailedExpectation], timeout: 10)
    }
    
    func testErrorMapping() {
        final class MappedError: Error {}
        
        let mappedErrorExpectation = expectation(description: "Expecting mapped error")
        mappedErrorExpectation.assertForOverFulfill = true
        
        let mappedError = MappedError()
        errorHandler.canHandleError = { error in
            return true
        }
        errorHandler.errorHandling = { error, completion in
            completion(.continueFailure(with: mappedError))
        }
        request = networkService.request(for: HTTPBinEndpoint.status(404), success: {
            XCTFail("Invalid case")
        }, failure: { error in
            XCTAssertTrue((error as? MappedError) === mappedError)
            mappedErrorExpectation.fulfill()
        })
        
        wait(for: [mappedErrorExpectation], timeout: 10)
    }

    func testFailureWithoutErrorHandling() {
        let networkService = NetworkService()

        let failureExpectation = expectation(description: "Expecting failure response")
        failureExpectation.assertForOverFulfill = true

        request = networkService.request(for: HTTPBinEndpoint.status(404), success: {
            XCTFail("Invalid case")
        }, failure: { _ in
            failureExpectation.fulfill()
        })

        wait(for: [failureExpectation], timeout: 10)
    }
}
