//
// Created by Nikita Zatsepilov on 2019-01-17.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

import Networking
import Alamofire

final class LoggingErrorHandler: ErrorHandler {

    func handleError<T>(_ requestError: RequestError<T>, completion: @escaping Completion) {
        print("Received request failure: \(requestError.error)")
        completion(.continueErrorHandling(with: requestError.error))
    }
}
