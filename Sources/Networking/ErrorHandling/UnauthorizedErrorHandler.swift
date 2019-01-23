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

    public func handleError<T>(_ error: RequestError<T>, completion: @escaping (ErrorHandlingResult) -> Void) {
        guard let response = error.response.response,
              response.statusCode == 401 else {
            completion(.continueErrorHandling(with: error.underlyingError))
            return
        }

        // `requestCompletedTime` is time interval since reference date
        let requestCompletedTime = error.response.timeline.requestCompletedTime
        let requestFailureDate = Date(timeIntervalSinceReferenceDate: requestCompletedTime)

        // Since multiple requests can be sent at same time, we have to avoid race conditions
        // For example 5 requests sent in parallel shouldn't trigger token refreshing multiple times
        // 1. Retry all requests, if token is already refreshed
        // 2. Fail all requests, if token refreshing has recently failed
        if let authToken = sessionService.authToken, authToken.expiryDate > requestFailureDate {
            completion(.retryNeeded)
            return
        } else if let tokenRefreshFailureDate = lastTokenRefreshFailureDate,
                  tokenRefreshFailureDate <= requestFailureDate {
            completion(.continueErrorHandling(with: error.underlyingError))
            return
        }

        items.append(AuthorizationErrorHandlerItem(error: error.underlyingError, completion: completion))
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
