//
// Created by Nikita Zatsepilov on 09/12/2018.
// Copyright (c) 2018 Ronas IT. All rights reserved.
//

import Alamofire
import Networking

final class LogErrorHandler: ErrorHandler {

    func handle<T>(error: inout Error, for response: DataResponse<T>?, endpoint: Endpoint) -> Bool {
        print("Request failed with error: \(error)")
        return false
    }
}
