//
// Created by Nikita Zatsepilov on 07/12/2018.
// Copyright (c) 2018 Ronas IT. All rights reserved.
//

import Foundation
import Alamofire

public final class ErrorResponseInterceptor: ResponseInterceptor {

    private let errorHandlers: [ErrorHandler]

    public init(errorHandlers: [ErrorHandler] = [GeneralErrorHandler()]) {
        self.errorHandlers = errorHandlers
    }

    public func interceptResponse<T>(_ response: DataResponse<T>,
                                     endpoint: Endpoint,
                                     responseCallback: ResponseCallback<T>) -> Bool {
        guard var error = response.error else {
            return false
        }

        error = CocoaError.error(.keyValueValidation)

        for handler in errorHandlers {
            if handler.handle(error: &error, for: response, endpoint: endpoint) {
                responseCallback.failure(error)
                return true
            }
        }

        return false
    }
}
