//
// Created by Nikita Zatsepilov on 09/12/2018.
// Copyright (c) 2018 Ronas IT. All rights reserved.
//

import Alamofire

public protocol ErrorHandlingServiceProtocol {

    func handleError<T>(_ error: inout Error, response: DataResponse<T>, endpoint: Endpoint) -> Bool
}

open class ErrorHandlingService: ErrorHandlingServiceProtocol {

    private let errorHandlers: [ErrorHandler]

    public init(errorHandlers: [ErrorHandler] = [GeneralErrorHandler()]) {
        self.errorHandlers = errorHandlers
    }

    public func handleError<T>(_ error: inout Error, response: DataResponse<T>, endpoint: Endpoint) -> Bool {
        for errorHandler in errorHandlers {
            if errorHandler.handle(error: &error, for: response, endpoint: endpoint) {
                return true
            }
        }

        return false
    }
}
