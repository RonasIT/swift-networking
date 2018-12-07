//
// Created by Nikita Zatsepilov on 07/12/2018.
// Copyright (c) 2018 Ronas IT. All rights reserved.
//

import Foundation
import Alamofire

public final class ErrorHandlersResponseInterceptor: ResponseInterceptor {

    private let errorHandlers: [ErrorHandler]

    public init(errorHandlers: [ErrorHandler]) {
        self.errorHandlers = errorHandlers
    }

    func interceptResponse<T>(of request: NetworkRequest,
                              response: DataResponse<T>,
                              endpoint: Endpoint,
                              responseCallback: ResponseCallback<T>) -> Bool {
        guard var error = response.error else {
            return false
        }

        for handler in errorHandlers {
            if handler.handle(error: &error, for: response, endpoint: endpoint) {
                responseCallback.failure(error)
                return true
            }
        }

        return false
    }
}
