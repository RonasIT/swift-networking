//
// Created by Nikita Zatsepilov on 2019-01-15.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

public protocol ErrorHandlingServiceProtocol {

    func handleError<T>(_ requestError: RequestError<T>, retrying: @escaping () -> Void, failure: @escaping Failure)
}

open class ErrorHandlingService: ErrorHandlingServiceProtocol {

    private let errorHandlers: [ErrorHandler]

    public init(errorHandlers: [ErrorHandler] = [GeneralErrorHandler()]) {
        self.errorHandlers = errorHandlers
    }

    public final func handleError<T>(_ requestError: RequestError<T>,
                                     retrying: @escaping () -> Void,
                                     failure: @escaping Failure) {
        guard let errorHandler = errorHandlers.first else {
            failure(requestError.error)
            return
        }

        handleErrorRecursive(
            requestError,
            errorHandler: errorHandler,
            retrying: retrying,
            failure: failure
        )
    }

    // MARK: - Private

    private func handleErrorRecursive<T>(_ requestError: RequestError<T>,
                                         errorHandler: ErrorHandler,
                                         retrying: @escaping () -> Void,
                                         failure: @escaping Failure) {
        var nextErrorHandler: ErrorHandler?
        if errorHandler !== errorHandlers.last {
            let errorHandlerIndexOrNil = errorHandlers.firstIndex { $0 === errorHandler }
            if let errorHandlerIndex = errorHandlerIndexOrNil {
                nextErrorHandler = errorHandlers[errorHandlerIndex + 1]
            }
        }

        errorHandler.handleError(requestError) { [weak self] result in
            guard let `self` = self else {
                return
            }

            switch result {
            case .retryNeeded:
                retrying()
            case .continueFailure(with: let error):
                failure(error)
            case .continueErrorHandling(with: let error):
                guard let nextErrorHandler = nextErrorHandler else {
                    failure(error)
                    return
                }

                // In this case current error handler returns result with new error (error of RequestError)
                // Which we should be sent to the next error handler
                let newError = RequestError(endpoint: requestError.endpoint,
                                            error: error,
                                            response: requestError.response)
                self.handleErrorRecursive(
                    newError,
                    errorHandler: nextErrorHandler,
                    retrying: retrying,
                    failure: failure
                )
            }
        }
    }
}
