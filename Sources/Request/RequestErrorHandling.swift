//
// Created by Nikita Zatsepilov on 30/11/2018.
// Copyright (c) 2018 Ronas IT. All rights reserved.
//

import Foundation
import Alamofire

protocol RequestErrorHandling {

    var errorHandlers: [ErrorHandler] { get set }
    var endpoint: Endpoint { get }

    func handleError<T>(_ error: Error,
                        `for` response: DataResponse<T>?,
                        failureHandler: FailureHandler)
}

extension RequestErrorHandling {

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