//
// Created by Nikita Zatsepilov on 2019-01-17.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

import Networking

final class LoggingErrorHandler: ErrorHandler {

    func handleError(with payload: ErrorPayload, completion: @escaping Completion) {
        print("Received request failure: \(payload.error)")
        completion(.continueErrorHandling(with: payload.error))
    }
}
