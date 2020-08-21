//
// Created by Nikita Zatsepilov on 2019-01-27.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

import Alamofire
@testable import Networking
import XCTest

final class GeneralErrorHandlerTests: XCTestCase {

    private lazy var errorHandler: GeneralErrorHandler = .init()

    func testErrorMappingForSupportedStatusCodes() {
        let expectedErrors: [GeneralRequestError] = [
            .noAuth,
            .forbidden,
            .notFound
        ]
        let failureResults: [RequestFailureResult] = [
            .responseWithStatusCode(401, error: MockError()),
            .responseWithStatusCode(403, error: MockError()),
            .responseWithStatusCode(404, error: MockError())
        ]
        testErrorHandling(withExpectedErrors: expectedErrors, requestFailureResults: failureResults)
    }

    func testErrorMappingForSupportedURLErrorCodes() {
        let expectedErrors: [GeneralRequestError] = [
            .noInternetConnection,
            .timedOut,
            .cancelled
        ]
        let failureResults: [RequestFailureResult] = [
            .errorWithoutResponse(error: URLError(.notConnectedToInternet)),
            .errorWithoutResponse(error: URLError(.timedOut)),
            .errorWithoutResponse(error: URLError(.cancelled))
        ]
        testErrorHandling(withExpectedErrors: expectedErrors, requestFailureResults: failureResults)
    }

    func testMappingSkippingForUnsupportedURLErrorAndStatusCode() {
        let firstFailureError = URLError(.badURL)
        let firstFailureResult = RequestFailureResult.errorWithoutResponse(error: firstFailureError)

        let secondFailureStatusCode = 429
        let secondFailureError = AFError.responseValidationFailed(
            reason: .unacceptableStatusCode(code: secondFailureStatusCode)
        )
        let secondFailureResult = RequestFailureResult.responseWithStatusCode(
            secondFailureStatusCode,
            error: secondFailureError
        )

        let expectation = self.expectation(description: "Expects correct error handling results")
        expectation.expectedFulfillmentCount = 2
        expectation.assertForOverFulfill = true

        testErrorHandling(failureResult: firstFailureResult) { result in
            switch result {
            case .continueErrorHandling(let error as URLError) where error.code == .badURL:
                expectation.fulfill()
            default:
                break
            }
        }
        testErrorHandling(failureResult: secondFailureResult) { result in
            switch result {
            case .continueErrorHandling(let error as AFError):
                switch error {
                case .responseValidationFailed(reason: .unacceptableStatusCode(code: secondFailureStatusCode)):
                    expectation.fulfill()
                default:
                    break
                }
            default:
                break
            }
        }

        wait(for: [expectation], timeout: 5)
    }

    func testEndpointErrorMapping() {
        let errorMappedByStatusCode = MockError()
        let errorMappedByURLErrorCode = MockError()

        var endpoint = MockEndpoint()
        endpoint.errorForStatusCode = errorMappedByStatusCode
        endpoint.errorForURLErrorCode = errorMappedByURLErrorCode

        let expectation = self.expectation(description: "Expects correct error handling results")
        expectation.expectedFulfillmentCount = 2
        expectation.assertForOverFulfill = true

        let failureResultWithStatusCode = RequestFailureResult.responseWithStatusCode(401, error: MockError())
        testErrorHandling(with: endpoint, failureResult: failureResultWithStatusCode) { result in
            switch result {
            case .continueErrorHandling(let error as MockError) where error === errorMappedByStatusCode:
                expectation.fulfill()
            default:
                break
            }
        }

        let failureResultWithURLError = RequestFailureResult.errorWithoutResponse(error: URLError(.notConnectedToInternet))
        testErrorHandling(with: endpoint, failureResult: failureResultWithURLError) { result in
            switch result {
            case .continueErrorHandling(let error as MockError) where error === errorMappedByURLErrorCode:
                expectation.fulfill()
            default:
                break
            }
        }

        wait(for: [expectation], timeout: 5)
    }

    func testErrorHandlingWithUnsupportedError() {
        let expectedError = MockError()
        let expectation = self.expectation(description: "Expects correct error handling result")

        testErrorHandling(failureResult: .errorWithoutResponse(error: expectedError)) { result in
            switch result {
            case .continueErrorHandling(let error as MockError) where error === expectedError:
                expectation.fulfill()
            default:
                break
            }
        }

        wait(for: [expectation], timeout: 5)
    }

    // MARK: - Private

    private func testErrorHandling(with endpoint: Endpoint = MockEndpoint(),
                                   failureResult: RequestFailureResult,
                                   completion: @escaping (ErrorHandlingResult) -> Void) {
        let errorHandler = GeneralErrorHandler()
        let response = failureResult.dataResponse
        let requestError = ErrorPayload(endpoint: endpoint, error: response.error!, response: response)
        errorHandler.handleError(requestError, completion: completion)
    }

    private func testErrorHandling(withExpectedErrors expectedErrors: [GeneralRequestError],
                                   requestFailureResults: [RequestFailureResult]) {

        let expectation = self.expectation(description: "Expects correct error handling results")
        expectation.expectedFulfillmentCount = expectedErrors.count
        expectation.assertForOverFulfill = true

        zip(expectedErrors, requestFailureResults).forEach { expectedError, requestFailureResult in
            testErrorHandling(failureResult: requestFailureResult) { result in
                switch result {
                case .continueErrorHandling(let error as GeneralRequestError) where error == expectedError:
                    expectation.fulfill()
                default:
                    break
                }
            }
        }

        wait(for: [expectation], timeout: 5)
    }
}

private enum RequestFailureResult {
    case responseWithStatusCode(Int, error: Error)
    case errorWithoutResponse(error: Error)

    var dataResponse: Alamofire.DataResponse<Any> {
        switch self {
        case let .responseWithStatusCode(statusCode, error):
            let url = URL(string: "https://apple.com")!
            let response = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)
            return DataResponse(request: nil, response: response, data: nil, result: .failure(error))
        case .errorWithoutResponse(let error):
            return DataResponse(request: nil, response: nil, data: nil, result: .failure(error))
        }
    }
}
