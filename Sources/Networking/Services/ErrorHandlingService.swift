//
// Created by Nikita Zatsepilov on 06/12/2018.
// Copyright (c) 2018 Ronas IT. All rights reserved.
//

import Foundation
import Alamofire

public protocol RequestErrorHandlingService {

    var errorHandlers: [ErrorHandler] { get }
}

open class GeneralRequestErrorHandlingService: RequestErrorHandlingService {

    public let errorHandlers: [ErrorHandler]

    public init(errorHandlers: [ErrorHandler] = [GeneralErrorHandler()]) {
        self.errorHandlers = errorHandlers
    }

    public func handleErrorResponse<T>(_ error: Error, request: Request, response: DataResponse<T>) {
//        var error = requestError.error
//        for handler in errorHandlers {
//            if handler.handle(error: &error, for: requestError.response, endpoint: requestError.endpoint) {
//                return
//            }
//        }
//        requestError.failure(error)
    }
}
