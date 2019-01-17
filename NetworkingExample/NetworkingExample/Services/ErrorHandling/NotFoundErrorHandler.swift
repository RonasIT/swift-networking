//
// Created by Nikita Zatsepilov on 2019-01-17.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

import Networking
import Alamofire

struct NotFoundError: LocalizedError {

    var errorDescription: String? {
        return "You received response with 404 status code"
    }
}

final class NotFoundErrorHandler: ErrorHandler {

    func canHandleError<T>(_ error: RequestError<T>) -> Bool {
        guard let error = error.underlyingError as? AFError,
              let responseCode = error.responseCode else {
            return false
        }
        return responseCode == 404
    }

    func handleError<T>(_ error: RequestError<T>, completion: @escaping (ErrorHandlingResult) -> Void) {

    }
}
