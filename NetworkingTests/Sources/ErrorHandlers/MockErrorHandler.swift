//
// Created by Nikita Zatsepilov on 2019-01-18.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

import Networking

final class MockError: Error {}

final class MockErrorHandler: ErrorHandler {

    var errorHandling: ((Error, (ErrorHandlingResult) -> Void) -> Void)?

    convenience init(errorHandling: @escaping ((Error, (ErrorHandlingResult) -> Void) -> Void)) {
        self.init()
        self.errorHandling = errorHandling
    }

    func handleError(with payload: ErrorPayload, completion: @escaping (ErrorHandlingResult) -> Void) {
        errorHandling?(payload.error, completion)
    }
}
