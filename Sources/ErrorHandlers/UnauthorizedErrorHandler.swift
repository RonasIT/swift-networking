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

    public func handleError(with payload: ErrorPayload,
                            completion: @escaping (ErrorHandlingResult) -> Void) {
        guard shouldHandleError(with: payload) else {
            completion(.continueErrorHandling(with: payload.error))
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
            let requestStartDate = payload.response.metrics?.taskInterval.start

            // Request started before token refreshing (used expired token),
            // but error received after token refreshing
            if let startDate = requestStartDate, startDate < tokenRefreshingCompletionDate {
                if isTokenRefreshed {
                    completion(.retryNeeded)
                } else {
                    completion(.continueFailure(with: payload.error))
                }
            } else {
                let failure = Failure(error: payload.error, completion: completion)
                enqueueFailure(failure)
            }
        default:
            let failure = Failure(error: payload.error, completion: completion)
            enqueueFailure(failure)
        }
    }

    // MARK: -  Private

    private func shouldHandleError(with payload: ErrorPayload) -> Bool {
        // Don't handle errors for endpoint without authorization,
        // because we can trigger token refreshing in wrong time
        // For example, on login request (auth is not required) server can respond
        // with 401 status code, when sent password is not valid.
        // We shouldn't trigger token refreshing for this case.
        return payload.endpoint.authorizationType != .none &&
               payload.statusCode == StatusCode.unauthorised401
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
            self.handleTokenRefreshCompletion(isTokenRefreshed: true)
        }, failure: { [weak self] _ in
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
