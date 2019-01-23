//
// Created by Nikita Zatsepilov on 2019-01-15.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

import Alamofire

public final class UnauthorizedErrorHandler: ErrorHandler {

    private let sessionService: SessionServiceProtocol

    private var isRefreshingToken: Bool = false
    private var items: [AuthorizationErrorHandlerItem] = []

    public init(sessionService: SessionServiceProtocol) {
        self.sessionService = sessionService
    }

    public func handleError<T>(_ error: RequestError<T>, completion: @escaping (ErrorHandlingResult) -> Void) {
        guard error.response.response?.statusCode == 401 else {
            completion(.continueErrorHandling(with: error.underlyingError))
            return
        }

        items.append(AuthorizationErrorHandlerItem(error: error.underlyingError, completion: completion))
        refreshTokenIfNeeded()
    }

    // MARK: - Private

    private func refreshTokenIfNeeded() {
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
        items.removeAll { item in
            if isErrorResolved {
                item.completion(.retryNeeded)
            } else {
                item.completion(.continueFailure(with: item.error))
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
