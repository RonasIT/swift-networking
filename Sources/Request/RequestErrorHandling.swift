//
// Created by Nikita Zatsepilov on 30/11/2018.
// Copyright (c) 2018 Ronas IT. All rights reserved.
//

import Foundation
import Alamofire

protocol RequestErrorHandling {

    // TODO: move `endpoint and `errorHandlers` to protocol (avoid duplication in Request protocol)
    var endpoint: Endpoint { get }
    var errorHandlers: [ErrorHandler] { get set }

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