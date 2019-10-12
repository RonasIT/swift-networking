//
// Created by Nikita Zatsepilov on 2019-01-27.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

@testable import Networking
import Alamofire
import XCTest

final class GeneralErrorHandlerTests: XCTestCase {

    func testErrorMapping() {
        let errors: [Error] = [
            NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut),
            NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet),
            NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled),
            AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 404)),
            AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 401))
        ]
        let expectedErrors: [GeneralRequestError] = [
            .timedOut,
            .noInternetConnection,
            .cancelled,
            .notFound,
            .noAuth
        ]
        let expectations: [XCTestExpectation] = expectedErrors.map { error in
            let expectation = XCTestExpectation(description: "Expecting receive \(error)")
            expectation.assertForOverFulfill = true
            return expectation
        }
        for index in 0..<expectations.count {
            let error = errors[index]
            let expectedError = expectedErrors[index]
            let expectation = expectations[index]
            executeErrorHandling(with: error) { result in
                switch result {
                case .continueErrorHandling(with: let error as GeneralRequestError) where error == expectedError:
                    expectation.fulfill()
                default:
                    XCTFail("Unexpected result")
                }
            }
        }

        wait(for: expectations, timeout: 5)
    }

    func testErrorHandlingWithUnsupportedAFErrorWithStatusCode() {
        let expectation = self.expectation(description: "Expecting same error from error handler")
        expectation.assertForOverFulfill = true

        let expectedError = AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: Int.max))
        executeErrorHandling(with: expectedError) { result in
            switch result {
            case .continueErrorHandling(with: AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: Int.max))):
                expectation.fulfill()
            default:
                XCTFail("Unexpected result")
            }
        }

        wait(for: [expectation], timeout: 3)
    }

    func testErrorHandlingWithUnsupportedAFErrorWithoutStatusCode() {
        let expectation = self.expectation(description: "Expecting same error from error handler")
        expectation.assertForOverFulfill = true

        let expectedError = AFError.parameterEncodingFailed(reason: .missingURL)
        executeErrorHandling(with: expectedError) { result in
            switch result {
            case .continueErrorHandling(with: AFError.parameterEncodingFailed(reason: .missingURL)):
                expectation.fulfill()
            default:
                XCTFail("Unexpected result")
            }
        }

        wait(for: [expectation], timeout: 3)
    }

    func testErrorHandlingWithUnsupportedError() {
        let expectation = self.expectation(description: "Expecting same error from error handler")
        expectation.assertForOverFulfill = true

        let expectedError = MockError()
        executeErrorHandling(with: expectedError) { result in
            switch result {
            case .continueErrorHandling(with: let error as MockError) where error === expectedError:
                expectation.fulfill()
            default:
                XCTFail("Invalid result")
            }
        }

        wait(for: [expectation], timeout: 3)
    }

    func testErrorHandlingWithUnsupportedURLError() {
        let expectation = self.expectation(description: "Expecting continue error handling result")
        expectation.assertForOverFulfill = true

        let expectedError = NSError(domain: NSURLErrorDomain, code: NSURLErrorBadURL)
        executeErrorHandling(with: expectedError) { result in
            switch result {
            case .continueErrorHandling(with: let error as NSError)
                 where error.domain == expectedError.domain && error.code == expectedError.code:
                expectation.fulfill()
            default:
                XCTFail("Invalid result")
            }
        }

        wait(for: [expectation], timeout: 3)
    }

    // MARK: - Private

    private func executeErrorHandling(with error: Error, completion: @escaping (ErrorHandlingResult) -> Void) {
        let errorHandler = GeneralErrorHandler()
        let response: DataResponse<Any> = .init(request: nil, response: nil, data: nil, result: .failure(error))
        let endpoint = MockEndpoint(result: error)
        let requestError = RequestError(endpoint: endpoint, error: error, response: response)
        errorHandler.handleError(requestError, completion: completion)
    }
}
