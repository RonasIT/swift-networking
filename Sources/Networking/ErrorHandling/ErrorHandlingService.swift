//
// Created by Nikita Zatsepilov on 2019-01-15.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

import Alamofire

public protocol ErrorHandlingServiceProtocol {

    func handleError(_ error: Error, completion: @escaping (ErrorHandlingResult) -> Void)
}

open class ErrorHandlingService: ErrorHandlingServiceProtocol {

    let errorHandlers: [ErrorHandler]

    public init(errorHandlers: [ErrorHandler]) {
        self.errorHandlers = errorHandlers
    }

    public func handleError(_ error: Error, completion: @escaping (ErrorHandlingResult) -> Void) {
        let errorHandlerOrNil = errorHandlers.first { $0.canHandleError(error) }
        guard let errorHandler = errorHandlerOrNil else {
            completion(.failure(error))
            return
        }

        errorHandler.handleError(error) { result in
            completion(result)
        }
    }
}
