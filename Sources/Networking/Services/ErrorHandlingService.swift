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

    public func handleError<T>(_ requestError: RequestError<T>, retrying: @escaping () -> Void, failure: @escaping Failure) {
        var previousErrorHandler: ErrorHandler?
        func handleErrorRecursive<T>(_ error: RequestError<T>) {
            guard let errorHandler = nextErrorHandler(for: error, previousErrorHandler: previousErrorHandler) else {
                failure(requestError.underlyingError)
                return
            }

            errorHandler.handleError(requestError) { result in
                switch result {
                case .continueErrorHandling(with: let error):
                    let updatedRequestError = RequestError(endpoint: requestError.endpoint,
                                                           underlyingError: error,
                                                           response: requestError.response)
                    handleErrorRecursive(updatedRequestError)
                case .continueFailure(with: let error):
                    failure(error)
                case .retryNeeded:
                    retrying()
                }
            }
        }

        handleErrorRecursive(requestError)
    }

    // MARK: - Private

    private func nextErrorHandler<T>(for requestError: RequestError<T>,
                                     previousErrorHandler: ErrorHandler? = nil) -> ErrorHandler? {
        #warning("FIXME")
        fatalError()
//        var startIndex = 0
//
//        // Update start index if needed
//        if let previousErrorHandler = previousErrorHandler {
//            let previousErrorHandlerIndexOrNil = errorHandlers.firstIndex { $0 === previousErrorHandler }
//            if let previousErrorHandlerIndex = previousErrorHandlerIndexOrNil {
//                startIndex = previousErrorHandlerIndex
//            }
//        }
//
//        // Find index of appropriate error handler from unchecked error handlers
//        let uncheckedErrorHandlers = errorHandlers[startIndex..<errorHandlers.count]
//        let errorHandlerIndexOrNil = uncheckedErrorHandlers.firstIndex { errorHandler in
//            return errorHandler.canHandleError(requestError)
//        }
//
//        if let errorHandlerIndex = errorHandlerIndexOrNil {
//            // Error handler found
//            return errorHandlers[errorHandlerIndex]
//        } else {
//            return nil
//        }
    }
}
