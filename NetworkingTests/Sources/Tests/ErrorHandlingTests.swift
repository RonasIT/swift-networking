//
// Created by Nikita Zatsepilov on 2019-01-18.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

import XCTest
@testable import Networking
import Alamofire

private enum PartialErrorHandlingChainTestKind {
    case testWithFailure
    case testWithRetry
}

private enum EndpointErrorMappingTestKind {
    case mappedUsingResponseCode(mappedError: MockError)
    case mappingUsingURLErrorCode(mappedError: MockError)
}

final class ErrorHandlingTests: XCTestCase {

    private lazy var errorHandler: MockErrorHandler = .init()
    private lazy var networkService: NetworkService = {
        let errorHandlingService = ErrorHandlingService(errorHandlers: [errorHandler])
        return MockNetworkService(errorHandlingService: errorHandlingService)
    }()

    private var request: CancellableRequest?
    
    override func tearDown() {
        super.tearDown()
        errorHandler.errorHandling = nil
        request = nil
    }

    func testEmptyErrorHandlingChain() {
        let expectation = self.expectation(description: "Expecting request failure")
        expectation.assertForOverFulfill = true

        let errorHandlingService = ErrorHandlingService(errorHandlers: [])
        let networkService = MockNetworkService(errorHandlingService: errorHandlingService)
        let endpoint = MockEndpoint(result: GeneralRequestError.notFound)
        request = networkService.request(for: endpoint, success: {
            XCTFail("Invalid case")
        }, failure: { error in
            switch error {
            case GeneralRequestError.notFound:
                expectation.fulfill()
            default:
                XCTFail("Received unexpected error")
            }
        })
        
        wait(for: [expectation], timeout: 5)
    }

    func testFullErrorHandlingChain() {
        let errorHandlingTriggeredExpectation = expectation(description: "Expecting error handling triggered multiple times")
        errorHandlingTriggeredExpectation.expectedFulfillmentCount = 3
        errorHandlingTriggeredExpectation.assertForOverFulfill = true

        let failureTriggeredExpectation = expectation(description: "Expecting request failure")
        failureTriggeredExpectation.expectedFulfillmentCount = 1
        failureTriggeredExpectation.assertForOverFulfill = true

        let numberOfErrors = errorHandlingTriggeredExpectation.expectedFulfillmentCount
        let expectedErrors = [Int](0..<numberOfErrors).map { _ in
            return MockError()
        }

        var errorHandlers = [ErrorHandler]()
        for i in 0..<expectedErrors.count {
            let expectedError = expectedErrors[i]
            let nextError = expectedError === expectedErrors.last ? nil : expectedErrors[i + 1]
            let errorHandler = MockErrorHandler { error, completion in
                switch error {
                case let error as MockError where error === expectedError:
                    errorHandlingTriggeredExpectation.fulfill()
                    if let nextError = nextError {
                        completion(.continueErrorHandling(with: nextError))
                    } else {
                        completion(.continueFailure(with: error))
                    }
                default:
                    XCTFail("Unexpected error")
                }
            }
            errorHandlers.append(errorHandler)
        }

        let errorHandlingService = ErrorHandlingService(errorHandlers: errorHandlers)
        let networkService = MockNetworkService(errorHandlingService: errorHandlingService)
        let endpoint = MockEndpoint(result: expectedErrors.first!)
        request = networkService.request(for: endpoint, success: {
            XCTFail("Invalid case")
        }, failure: { error in
            switch error {
            case let error as MockError where error === expectedErrors.last:
                failureTriggeredExpectation.fulfill()
            default:
                XCTFail("Received unexpected error")
            }
        })

        let expectations = [errorHandlingTriggeredExpectation, failureTriggeredExpectation]
        wait(for: expectations, timeout: 10, enforceOrder: true)
    }

    func testPartialErrorHandlingChainWithFailure() {
        testPartialErrorHandlingChain(testKind: .testWithFailure)
    }
    
    func testPartialErrorHandlingChainWithRetry() {
        testPartialErrorHandlingChain(testKind: .testWithRetry)
    }

    func testFailureWithoutErrorHandling() {
        let networkService = MockNetworkService()

        let failureExpectation = expectation(description: "Expecting failure response")
        failureExpectation.assertForOverFulfill = true

        let endpoint = MockEndpoint(result: GeneralRequestError.notFound)
        request = networkService.request(for: endpoint, success: {
            XCTFail("Invalid case")
        }, failure: { _ in
            failureExpectation.fulfill()
        })

        wait(for: [failureExpectation], timeout: 10)
    }

    func testErrorHandlingWithMappedEndpointErrorByResponseCode() {
        let mappedError = MockError()
        testErrorHandlingWithMappedEndpointError(testKind: .mappedUsingResponseCode(mappedError: mappedError))
    }

    func testErrorHandlingWithMappedEndpointErrorByURLErrorCode() {
        let mappedError = MockError()
        testErrorHandlingWithMappedEndpointError(testKind: .mappingUsingURLErrorCode(mappedError: mappedError))
    }

    func testErrorHandlingMemoryLeaks() {
        let lifecycleExpectation = expectation(description: "Expecting nil in weak network service")

        let errorHandler = MockErrorHandler { _, _ in
            XCTFail("Memory leak happened")
        }

        var errorHandlingService: ErrorHandlingService? = ErrorHandlingService(errorHandlers: [errorHandler])
        weak var weakErrorHandlingService = errorHandlingService

        var networkService: NetworkService? = MockNetworkService(errorHandlingService: errorHandlingService)
        weak var weakNetworkService = networkService

        let endpoint = MockEndpoint(result: GeneralRequestError.notFound)
        request = networkService?.request(for: endpoint, success: {
            XCTFail("Memory leak happened")
        }, failure: { _ in
            XCTFail("Memory leak happened")
        })

        // Destroy strong references
        errorHandlingService = nil
        networkService = nil

        _ = XCTWaiter.wait(for: [lifecycleExpectation], timeout: 5)
        XCTAssertNil(weakNetworkService)
        XCTAssertNil(weakErrorHandlingService)
        lifecycleExpectation.fulfill()
    }

    // MARK: - Private

    private func testPartialErrorHandlingChain(testKind: PartialErrorHandlingChainTestKind) {
        let errorHandlingTriggeredExpectation = XCTestExpectation(description: "Expecting error handling triggered multiple times")
        errorHandlingTriggeredExpectation.assertForOverFulfill = true

        let completionExpectation = XCTestExpectation(description: "Expecting test completion")
        completionExpectation.assertForOverFulfill = true

        let firstError = MockError()
        let secondError = MockError()
        errorHandlingTriggeredExpectation.expectedFulfillmentCount = 2

        let errorHandlers = [
            MockErrorHandler { error, completion in
                switch error {
                case let error as MockError where error === firstError:
                    errorHandlingTriggeredExpectation.fulfill()
                    completion(.continueErrorHandling(with: secondError))
                default:
                    XCTFail("Invalid error")
                }
            },
            MockErrorHandler { error, completion in
                switch error {
                case let error as MockError where error === secondError:
                    errorHandlingTriggeredExpectation.fulfill()
                    switch testKind {
                    case .testWithFailure:
                        completion(.continueFailure(with: secondError))
                    case .testWithRetry:
                        completion(.retryNeeded)
                        completionExpectation.fulfill()
                    }
                default:
                    XCTFail("Invalid error")
                }
            },
            MockErrorHandler { _, _ in
                XCTFail("Error handling should be interrupted on second error handler")
            }
        ]

        let errorHandlingService = ErrorHandlingService(errorHandlers: errorHandlers)
        let networkService = MockNetworkService(errorHandlingService: errorHandlingService)

        let endpoint = MockEndpoint(result: firstError)
        request = networkService.request(for: endpoint, success: {
            XCTFail("Invalid case")
        }, failure: { error in
            guard let error = error as? MockError, error === secondError else {
                XCTFail("Unexpected error")
                return
            }

            completionExpectation.fulfill()
        })

        wait(for: [errorHandlingTriggeredExpectation, completionExpectation], timeout: 10, enforceOrder: true)
    }

    private func testErrorHandlingWithMappedEndpointError(testKind: EndpointErrorMappingTestKind) {
        var endpoint: MockEndpoint
        var expectedError: MockError
        switch testKind {
        case .mappedUsingResponseCode(mappedError: let mappedError):
            let error = AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 400))
            endpoint = MockEndpoint(result: error)
            endpoint.errorForResponseCode = mappedError
            expectedError = mappedError
        case .mappingUsingURLErrorCode(mappedError: let mappedError):
            let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled)
            endpoint = MockEndpoint(result: error)
            endpoint.errorForURLErrorCode = mappedError
            expectedError = mappedError
        }

        let errorHandlingService = ErrorHandlingService(errorHandlers: [GeneralErrorHandler()])
        let networkService = MockNetworkService(errorHandlingService: errorHandlingService)

        let failureExpectation = expectation(description: "Expecting failure response")
        failureExpectation.assertForOverFulfill = true

        request = networkService.request(for: endpoint, success: {
            XCTFail("Invalid case")
        }, failure: { error in
            guard let error = error as? MockError, error === expectedError  else {
                XCTFail("Unexpected error")
                return
            }
            failureExpectation.fulfill()
        })

        wait(for: [failureExpectation], timeout: 10)
    }
}
