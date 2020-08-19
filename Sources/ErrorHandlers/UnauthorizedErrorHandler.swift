//
// Created by Nikita Zatsepilov on 2019-01-15.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

import Alamofire

public final class UnauthorizedErrorHandler: ErrorHandler {

    private enum State {
        case none
        case resolvingError
        case errorResolved(resolveDate: Date, isTokenRefreshed: Bool)
    }

    private final class Failure {

        let error: Error
        let completion: (ErrorHandlingResult) -> Void

        init(error: Error, completion: @escaping (ErrorHandlingResult) -> Void) {
            self.error = error
            self.completion = completion
        }
    }

    private let accessTokenSupervisor: AccessTokenSupervisor
    private var state: State = .none
    private var failures: [Failure] = []

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

    public func handleError<T>(_ requestError: RequestError<T>,
                               completion: @escaping (ErrorHandlingResult) -> Void) {
        guard shouldHandleRequestError(requestError) else {
            completion(.continueErrorHandling(with: requestError.error))
            return
        }

        // We have to be sure, that token won't be refreshed multiple times
        // since we can receive errors of multiple requests in different time
        // For example, we sent 5 requests, and received only 3 errors.
        // We refreshed token and handled this 3 errors.
        // A bit later we received 2 remaining errors of long requests.
        // Since token was already refreshed, we won't refresh it again for remaining errors.
        switch state {
        case let .errorResolved(tokenRefreshingCompletionDate, isTokenRefreshed):
            let requestStartDate = requestError.response.metrics?.taskInterval.start

            // Request started before token refreshing (used expired token),
            // but error received after token refreshing
            if let startDate = requestStartDate, startDate < tokenRefreshingCompletionDate {
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
                let failure = Failure(error: requestError.error, completion: completion)
                enqueueFailure(failure)
            }
        default:
            let failure = Failure(error: requestError.error, completion: completion)
            enqueueFailure(failure)
        }
    }

    // MARK: - Private

    private func shouldHandleRequestError<T>(_ requestError: RequestError<T>) -> Bool {
        // Don't handle errors for endpoint without authorization,
        // because we can trigger token refreshing in wrong time
        // For example, on login request (auth is not required) server can respond
        // with 401 status code, when sent password is not valid.
        // We shouldn't trigger token refreshing for this case.
        return requestError.endpoint.requiresAuthorization &&
               requestError.response.response?.statusCode == 401
    }

    private func enqueueFailure(_ failure: Failure) {
        failures.append(failure)
        resolveError()
    }

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
            self.handleTokenRefreshCompletion(isTokenRefreshed: true)
        }, failure: { [weak self] error in
            Logging.log(
                type: .fault,
                category: .accessTokenRefreshing,
                "Authorization token refreshing failed with error: \(error)"
            )
            self?.handleTokenRefreshCompletion(isTokenRefreshed: false)
        })
    }

    private func handleTokenRefreshCompletion(isTokenRefreshed: Bool) {
        state = .errorResolved(resolveDate: Date(), isTokenRefreshed: isTokenRefreshed)
        failures.forEach { failure in
            if isTokenRefreshed {
                failure.completion(.retryNeeded)
            } else {
                failure.completion(.continueErrorHandling(with: failure.error))
            }
        }
        failures.removeAll()
    }
}
