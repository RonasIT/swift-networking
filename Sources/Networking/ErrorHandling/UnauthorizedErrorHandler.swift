//
// Created by Nikita Zatsepilov on 2019-01-15.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

import Alamofire

public final class UnauthorizedErrorHandler: ErrorHandler {

    private enum State {
        case none
        case resolvingError
        case errorResolved(atDate: Date, successful: Bool)
    }

    private let accessTokenSupervisor: AccessTokenSupervisor
    private var state: State = .none
    private var items: [AuthorizationErrorHandlerItem] = []

    private var isResolvingError: Bool {
        switch state {
        case .resolvingError:
            return true
        default:
            return false
        }
    }

    public init(accessTokenSupervisor: AccessTokenSupervisor) {
        self.accessTokenSupervisor = accessTokenSupervisor
    }

    public func handleError<T>(_ requestError: RequestError<T>, completion: @escaping (ErrorHandlingResult) -> Void) {
        guard let error = requestError.error as? AFError,
              error.responseCode == 401 else {
            completion(.continueErrorHandling(with: requestError.error))
            return
        }

        func enqueueFailure() {
            Logging.log(
                type: .debug,
                category: .accessTokenRefreshing,
                "\(requestError) - Enqueued for future retry"
            )
            items.append(AuthorizationErrorHandlerItem(error: requestError.error, completion: completion))
            resolveError()
        }

        // We have to be sure, that token won't be refreshed multiple times
        // since we can receive errors of multiple requests in different time
        // For example, we sent 5 requests, and received only 3 errors.
        // We refreshed token and handled this 3 errors.
        // A bit later we received 2 remaining errors of long requests.
        // Since token was already refreshed, we won't refresh it again for remaining errors.
        switch state {
        case let .errorResolved(tokenRefreshingCompletionDate, isTokenRefreshed):
            // Time from `Timeline` is timeIntervalSinceReferenceDate
            let timeline = requestError.response.timeline
            let requestStartDate = Date(timeIntervalSinceReferenceDate: timeline.requestStartTime)

            // Request started before token refreshing (used expired token),
            // but error received after token refreshing
            if requestStartDate < tokenRefreshingCompletionDate {
                if isTokenRefreshed {
                    Logging.log(
                        type: .debug,
                        category: .accessTokenRefreshing,
                        "\(requestError) - Received after recent successful access token refreshing, retrying request"
                    )
                    completion(.retryNeeded)
                } else {
                    Logging.log(
                        type: .debug,
                        category: .accessTokenRefreshing,
                        "\(requestError) - Received after recent failed access token refreshing, failing request"
                    )
                    completion(.continueFailure(with: requestError.error))
                }
            } else {
                Logging.log(
                    type: .fault,
                    category: .accessTokenRefreshing,
                    """
                    "\(requestError) - Unexpected failure, because access token was recently refreshed. \
                    Trying to refresh access token again."
                    """
                )
                enqueueFailure()
            }
        default:
            enqueueFailure()
        }
    }

    // MARK: - Private

    private func resolveError() {
        guard !isResolvingError else {
            return
        }

        state = .resolvingError
        accessTokenSupervisor.refreshAccessToken(success: { [weak self] in
            guard let self = self else {
                return
            }
            let accessToken = self.accessTokenSupervisor.accessToken ?? "nil"
            Logging.log(
                type: .debug,
                category: .accessTokenRefreshing,
                "Authorization token successfully refreshed, new token: `\(accessToken)`"
            )
            self.finish(isErrorResolved: true)
        }, failure: { [weak self] error in
            Logging.log(
                type: .fault,
                category: .accessTokenRefreshing,
                "Authorization token refreshing failed with error: \(error)"
            )
            self?.finish(isErrorResolved: false)
        })
    }

    private func finish(isErrorResolved: Bool) {
        state = .errorResolved(atDate: Date(), successful: isErrorResolved)
        items.forEach { item in
            if isErrorResolved {
                item.completion(.retryNeeded)
            } else {
                item.completion(.continueErrorHandling(with: item.error))
            }
        }
        items.removeAll()
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
