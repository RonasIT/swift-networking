//
// Created by Nikita Zatsepilov on 2019-01-18.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

import Networking

final class MockErrorHandler: ErrorHandler {

    var canHandleError: ((Error) -> Bool)?
    var errorHandling: ((Error, (ErrorHandlingResult) -> Void) -> Void)?

    func canHandleError<T>(_ error: RequestError<T>) -> Bool {
        return canHandleError?(error.underlyingError) ?? false
    }

    func handleError<T>(_ error: RequestError<T>, completion: @escaping (ErrorHandlingResult) -> Void) {
        errorHandling?(error.underlyingError, completion)
    }
}
