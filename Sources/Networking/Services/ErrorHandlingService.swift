//
// Created by Nikita Zatsepilov on 2019-01-15.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

public protocol ErrorHandlingServiceProtocol {

    func handleError<T>(_ error: RequestError<T>, completion: @escaping (ErrorHandlingResult) -> Void)
}

open class ErrorHandlingService: ErrorHandlingServiceProtocol {

    private let errorHandlers: [ErrorHandler]

    public init(errorHandlers: [ErrorHandler]) {
        self.errorHandlers = errorHandlers
    }

    public func handleError<T>(_ error: RequestError<T>, completion: @escaping (ErrorHandlingResult) -> Void) {
        let errorHandlerOrNil = errorHandlers.first { $0.canHandleError(error) }
        if let errorHandler = errorHandlerOrNil {
            errorHandler.handleError(error, completion: completion)
        } else {
            completion(.continueFailure(with: error.underlyingError))
        }
    }
}
