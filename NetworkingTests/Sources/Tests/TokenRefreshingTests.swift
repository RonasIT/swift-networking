//
// Created by Nikita Zatsepilov on 2019-01-18.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

@testable import Networking
import XCTest
import Alamofire

final class TokenRefreshingTests: XCTestCase {

    private typealias Request = Networking.Request

    private lazy var sessionService: MockSessionService = {
        return MockSessionService()
    }()

    private lazy var errorHandlingService: ErrorHandlingServiceProtocol = {
        return ErrorHandlingService(errorHandlers: [
            UnauthorizedErrorHandler(accessTokenSupervisor: sessionService)
        ])
    }()

    private lazy var requestAdaptingService: RequestAdaptingServiceProtocol = {
        return RequestAdaptingService(requestAdapters: [
            TokenRequestAdapter(accessTokenSupervisor: sessionService)
        ])
    }()

    private lazy var networkService: NetworkService = {
        return MockNetworkService(requestAdaptingService: requestAdaptingService,
                                  errorHandlingService: errorHandlingService)
    }()

    override func tearDown() {
        super.tearDown()
        sessionService.updateToken(to: nil)
    }

    func testTokenRefreshingWithSuccess() {
        let tokenRefreshingStartedExpectation = expectation(description: "Expecting token refreshing")
        tokenRefreshingStartedExpectation.assertForOverFulfill = true

        let successResponseExpectation = expectation(description: "Expecting success in response")
        successResponseExpectation.assertForOverFulfill = true
        successResponseExpectation.expectedFulfillmentCount = 10

        let maxRequestDelay: TimeInterval = 5
        let maxTokenRefreshingDelay: TimeInterval = 5

        sessionService.tokenRefreshHandler = { success, _ in
            let delay = TimeInterval.random(in: 1...maxTokenRefreshingDelay)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                tokenRefreshingStartedExpectation.fulfill()
                success?(MockSessionService.Constants.validAccessToken)
            }
        }

        var endpoint = MockEndpoint()
        endpoint.requiresAuthorization = true
        endpoint.expectedAccessToken = MockSessionService.Constants.validAccessToken

        let array = [Int](0..<successResponseExpectation.expectedFulfillmentCount)
        let requests = array.map { _ -> CancellableRequest in
            endpoint.responseDelay = .random(in: 1...maxRequestDelay)
            return networkService.request(for: endpoint, success: {
                successResponseExpectation.fulfill()
            }, failure: { _ in
                XCTFail("Invalid case")
            })
        }

        print("Testing \(requests.count) requests...")

        let expectations = [tokenRefreshingStartedExpectation, successResponseExpectation]
        let timeout = maxTokenRefreshingDelay + maxRequestDelay * 2
        wait(for: expectations, timeout: timeout + 1, enforceOrder: true)
    }

    func testTokenRefreshingWithFailure() {
        let tokenRefreshingStartedExpectation = expectation(description: "Expecting token refresh")
        tokenRefreshingStartedExpectation.assertForOverFulfill = true

        let failureResponseExpectation = expectation(description: "Expecting failure in response")
        failureResponseExpectation.assertForOverFulfill = true
        failureResponseExpectation.expectedFulfillmentCount = 10

        let maxRequestDelay: TimeInterval = 5
        let maxTokenRefreshingDelay: TimeInterval = 5

        let tokenRefreshError = MockError()
        sessionService.tokenRefreshHandler = { _, failure in
            let delay = TimeInterval.random(in: 1...maxTokenRefreshingDelay)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                tokenRefreshingStartedExpectation.fulfill()
                failure?(tokenRefreshError)
            }
        }

        var endpoint = MockEndpoint()
        endpoint.requiresAuthorization = true
        endpoint.expectedAccessToken = MockSessionService.Constants.validAccessToken
        let array = [Int](0..<failureResponseExpectation.expectedFulfillmentCount)
        let requests = array.map { _ -> CancellableRequest in
            endpoint.responseDelay = .random(in: 1...maxRequestDelay)
            return networkService.request(for: endpoint, success: {
                XCTFail("Invalid case")
            }, failure: { error in
                if let error = error as? MockError {
                    XCTAssertFalse(error === tokenRefreshError, "Request shouldn't fail with error of token refreshing")
                }
                failureResponseExpectation.fulfill()
            })
        }
        print("Testing \(requests.count) requests...")

        let expectations = [tokenRefreshingStartedExpectation, failureResponseExpectation]
        let timeout = maxTokenRefreshingDelay + maxRequestDelay
        wait(for: expectations, timeout: timeout, enforceOrder: true)
    }

    func testUnauthorizedErrorHandlerWithUnsupportedError() {
        let errorHandler = UnauthorizedErrorHandler(accessTokenSupervisor: sessionService)
        let unsupportedError = MockError()
        let response: Alamofire.DataResponse<Any> = .init(request: nil, response: nil, data: nil, result: .failure(unsupportedError))
        var endpoint = MockEndpoint(result: unsupportedError)
        endpoint.requiresAuthorization = true
        let requestError = ErrorPayload(endpoint: endpoint, error: unsupportedError, response: response)

        let expectation = self.expectation(description: "Expecting continue error handling result")
        expectation.assertForOverFulfill = true
        errorHandler.handleError(requestError) { result in
            switch result {
            case .continueErrorHandling(with: let error as MockError) where error === unsupportedError:
                expectation.fulfill()
            default:
                XCTFail("Unexpected result")
            }
        }

        wait(for: [expectation], timeout: 3)
    }

    func testUnauthorizedErrorHandlerWithNotAuthorizedEndpoint() {
        let expectation = self.expectation(description: "Expecting continue error handling result")
        expectation.assertForOverFulfill = true

        let urlResponse = HTTPURLResponse(
            url: URL(string: "https://apple.com")!,
            statusCode: 401,
            httpVersion: nil,
            headerFields: nil
        )
        let error = MockError()
        let response: Alamofire.DataResponse<Any> = .init(
            request: nil,
            response: urlResponse,
            data: nil,
            result: .failure(error)
        )

        var endpoint = MockEndpoint(result: error)
        endpoint.requiresAuthorization = false

        let requestError = ErrorPayload(endpoint: endpoint, error: error, response: response)
        let errorHandler = UnauthorizedErrorHandler(accessTokenSupervisor: sessionService)
        sessionService.tokenRefreshHandler = { _, _ in
            XCTFail("Token refreshing shouldn't be triggered")
        }
        errorHandler.handleError(requestError) { result in
            switch result {
            case .continueErrorHandling(with: let error as MockError) where error === error:
                expectation.fulfill()
            default:
                XCTFail("Unexpected result")
            }
        }

        wait(for: [expectation], timeout: 5)
    }

    func testTokenRequestAdapter() {
        func makeRequest(for endpoint: Endpoint) -> Request {
            return Request(sessionManager: .default, endpoint: endpoint)
        }

        func authorizationHeaderNotExists(in request: AdaptiveRequest) -> Bool {
            let key = RequestHeaders.authorization("").key
            return !request.headers.contains { $0.key == key }
        }

        func authorizationTokenExists(in request: AdaptiveRequest, token: String) -> Bool {
            let expectedHeader = RequestHeaders.authorization(token)
            return request.headers.contains { header in
                return header.key == expectedHeader.key && header.value == expectedHeader.value
            }
        }

        let sessionService = MockSessionService()
        let tokenRequestAdapter = TokenRequestAdapter(accessTokenSupervisor: sessionService)
        let requestAdaptingService = RequestAdaptingService(requestAdapters: [tokenRequestAdapter])

        sessionService.updateToken(to: nil)
        var endpoint = MockEndpoint()
        endpoint.requiresAuthorization = false
        let unauthorizedRequest = makeRequest(for: endpoint)
        requestAdaptingService.adapt(unauthorizedRequest)
        XCTAssertTrue(authorizationHeaderNotExists(in: unauthorizedRequest))

        let token = "accessToken"
        sessionService.updateToken(to: token)
        endpoint.requiresAuthorization = true
        let authorizedRequest = makeRequest(for: endpoint)
        requestAdaptingService.adapt(authorizedRequest)
        XCTAssertTrue(authorizationTokenExists(in: authorizedRequest, token: token))
    }
}
