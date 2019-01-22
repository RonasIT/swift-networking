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
        errorHandler.errorHandling = nil
    }

    func testFullErrorHandlingChain() {
        let errors = [MockError(), MockError(), MockError()]
        var errorHandlers = [ErrorHandler]()
        errorHandlers.reserveCapacity(errors.count)
        for i in 0..<errors.count {
            let previousError: MockError? = i > 0 ? errors[i - 1] : nil
            errorHandlers.append(MockErrorHandler { error, completion in
                // Validate error if we have expected error
                if let expectedError = previousError {
                    guard let error = error as? MockError else {
                        XCTFail("Test uses mock errors")
                        return
                    }
                    XCTAssertTrue(error === expectedError)
                }
                completion(.continueErrorHandling(with: errors[i]))
            })
        }

        let errorHandlingTriggeredExpectation = expectation(description: "Expecting error handling triggered multiple times")
        errorHandlingTriggeredExpectation.assertForOverFulfill = true
        errorHandlingTriggeredExpectation.expectedFulfillmentCount = errors.count

        let errorHandlingService = ErrorHandlingService(errorHandlers: errorHandlers)
        let networkService = NetworkService(errorHandlingService: errorHandlingService)
        request = networkService.request(for: HTTPBinEndpoint.status(500), success: {

        }, failure: { error in
            guard let error = error as? MockError,
                  let expectedError = errors.last else {
                XCTFail("Invalid case")
                return
            }
            XCTAssertTrue(error === expectedError)
        })
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
