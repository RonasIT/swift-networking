//
// Created by Nikita Zatsepilov on 2019-01-15.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

import Alamofire

protocol UnauthorizedErrorHandlerInput: AnyObject {

    func unauthorizedErrorResolved()
    func unauthorizedErrorResolvingFailed(with error: Error)
}

protocol UnauthorizedErrorHandlerOutput: AnyObject {

    func unauthorizedErrorHandlerDidReceiveError(_ input: UnauthorizedErrorHandlerInput)
}

final class UnauthorizedErrorHandler: ErrorHandler {

    public weak var output: UnauthorizedErrorHandlerOutput?

    private var isWaitingResolution: Bool = false
    private var items: [AuthorizationErrorHandlerItem] = []

    public func canHandleError<T>(_ error: RequestError<T>) -> Bool {
        guard let statusCode = error.response.response?.statusCode else {
            return false
        }
        return statusCode == 401
    }

    public func handleError<T>(_ error: RequestError<T>, completion: @escaping (ErrorHandlingResult) -> Void) {
        guard canHandleError(error) else {
            completion(.continueFailure(with: error.underlyingError))
            return
        }

        items.append(AuthorizationErrorHandlerItem(error: error.underlyingError, completion: completion))
        if !isWaitingResolution {
            output?.unauthorizedErrorHandlerDidReceiveError(self)
            isWaitingResolution = true
        }
    }

    // MARK: - Private

    private func finish(isErrorResolved: Bool) {
        items.removeAll { item in
            if isErrorResolved {
                item.completion(.retryNeeded)
            } else {
                item.completion(.continueFailure(with: item.error))
            }
            return true
        }
    }
}

// MARK: - RequestAuthErrorHandlerInput

extension UnauthorizedErrorHandler: UnauthorizedErrorHandlerInput {

    func unauthorizedErrorResolvingFailed(with error: Error) {
        finish(isErrorResolved: false)
    }

    func unauthorizedErrorResolved() {
        finish(isErrorResolved: true)
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
