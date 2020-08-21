//
// Created by Nikita Zatsepilov on 2019-01-15.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

public protocol ErrorHandlingServiceProtocol {
    func handleError(with payload: ErrorPayload,
                     retrying: @escaping () -> Void,
                     failure: @escaping Failure)
}

open class ErrorHandlingService: ErrorHandlingServiceProtocol {

    private let errorHandlers: [ErrorHandler]

    public init(errorHandlers: [ErrorHandler] = [GeneralErrorHandler()]) {
        self.errorHandlers = errorHandlers
    }

    public final func handleError(with payload: ErrorPayload,
                                  retrying: @escaping () -> Void,
                                  failure: @escaping Failure) {
        guard let errorHandler = errorHandlers.first else {
            failure(payload.error)
            return
        }
        handleErrorRecursive(
            with: payload,
            errorHandler: errorHandler,
            retrying: retrying,
            failure: failure
        )
    }

    // MARK: -  Private

    private func handleErrorRecursive(with payload: ErrorPayload,
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

        errorHandler.handleError(with: payload) { [weak self] result in
            guard let self = self else {
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

                // In this case current error handler returns result with new error (error of RequestError),
                // which should be sent to the next error handler
                let payload = ErrorPayload(endpoint: payload.endpoint, error: error, response: payload.response)
                self.handleErrorRecursive(
                    with: payload,
                    errorHandler: nextErrorHandler,
                    retrying: retrying,
                    failure: failure
                )
            }
        }
    }
}
