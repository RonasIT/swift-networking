//
// Created by Nikita Zatsepilov on 30/11/2018.
// Copyright (c) 2018 Ronas IT. All rights reserved.
//

import Foundation
import Alamofire

public protocol ErrorHandler {
    func handle<T>(error: inout Error, for response: DataResponse<T>?, endpoint: Endpoint) -> Bool
}

protocol RequestErrorHandling {

    typealias Failure = BasicRequest.Failure

    var errorHandlers: [ErrorHandler] { get }

    func handleError<T>(_ error: Error, `for` response: DataResponse<T>?, failure: Failure)
}

extension RequestErrorHandling where Self: BasicRequest {

    func handleError<T>(_ error: Error, `for` response: DataResponse<T>?, failure: Failure) {
        var error = error
        for handler in errorHandlers {
            if handler.handle(error: &error, for: response, endpoint: endpoint) {
                return
            }
        }
        failure(error)
    }
}
