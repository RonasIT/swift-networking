//
// Created by Nikita Zatsepilov on 30/11/2018.
// Copyright (c) 2018 Ronas IT. All rights reserved.
//

import Foundation
import Alamofire

protocol RequestErrorHandling {

    typealias FailureHandler = Request.FailureHandler

    func handleError<T>(_ error: Error,
                        `for` response: DataResponse<T>?,
                        failureHandler: FailureHandler)
}

extension RequestErrorHandling where Self: BasicRequest {

    func handleError<T>(_ error: Error,
                        `for` response: DataResponse<T>?,
                        failureHandler: FailureHandler) {
        var error = error
        for handler in errorHandlers {
            if handler.handle(error: &error, for: response, endpoint: endpoint) {
                return
            }
        }
        failureHandler(error)
    }
}