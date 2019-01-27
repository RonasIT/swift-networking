//
// Created by Nikita Zatsepilov on 2019-01-15.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

import Alamofire

public final class UnauthorizedErrorHandler: ErrorHandler {

    private let sessionService: SessionServiceProtocol
    private var isRefreshingToken: Bool = false
    private var items: [AuthorizationErrorHandlerItem] = []

    private var lastTokenRefreshFailureDate: Date?

    public init(sessionService: SessionServiceProtocol) {
        self.sessionService = sessionService
    }

    public func handleError<T>(_ requestError: RequestError<T>, completion: @escaping (ErrorHandlingResult) -> Void) {
        guard let error = requestError.error as? AFError,
              error.responseCode == 401 else {
            completion(.continueErrorHandling(with: requestError.error))
            return
        }

        // `requestCompletedTime` is time interval since reference date
        let requestCompletedTime = requestError.response.timeline.requestCompletedTime
        let requestFailureDate = Date(timeIntervalSinceReferenceDate: requestCompletedTime)

        // Since multiple requests can be failed in short time (for example during 10 seconds),
        // we have to avoid race conditions.

        // 1. We sent two requests - REQUEST_A and REQUEST_B
        // 2. We received error for REQUEST_A, but REQUEST_B still not received response
        // 3. Error of REQUEST_A triggered token refreshing, while REQUEST_B still not received response
        // 4. Token refreshing completed, but we still waiting response of REQUEST_B
        // 5. REQUEST_B failed with unauthorized error
        // 6. What to do next? Token is valid, so we have to retry REQUEST_B instead of triggering token refreshing
        // To achieve logic in point 6, we should check token before token refreshing.
        // Same we need to do when token refreshing failed, but with date of token refreshing failure
        // For more check `TokenRefreshingTests.swift`

        if let authToken = sessionService.authToken, authToken.expirationDate > requestFailureDate {
            // Token has been refreshed recently
            completion(.retryNeeded)
            return
        } else if let tokenRefreshFailureDate = lastTokenRefreshFailureDate,
                  tokenRefreshFailureDate <= requestFailureDate {
            // Token refreshing has been failed recently
            completion(.continueErrorHandling(with: requestError.error))
            return
        }

        items.append(AuthorizationErrorHandlerItem(error: requestError.error, completion: completion))
        startTokenRefreshingIfNeeded()
    }

    // MARK: - Private

    private func startTokenRefreshingIfNeeded() {
        guard !isRefreshingToken else {
            return
        }

        isRefreshingToken = true
        sessionService.refreshAuthToken(success: { [weak self] in
            self?.finish(isErrorResolved: true)
        }, failure: { [weak self] _ in
            self?.finish(isErrorResolved: false)
        })
    }

    private func finish(isErrorResolved: Bool) {
        lastTokenRefreshFailureDate = isErrorResolved ? nil : Date()
        items.removeAll { item in
            if isErrorResolved {
                item.completion(.retryNeeded)
            } else {
                item.completion(.continueErrorHandling(with: item.error))
            }
            return true
        }
        isRefreshingToken = false
    }
}

private final class AuthorizationErrorHandlerItem {

    let error: Error
    let completion: (ErrorHandlingResult) -> Void

    init(error: Error, completion: @escaping (ErrorHandlingResult) -> Void) {
        self.error = error
        self.completion = completion
    }
}
