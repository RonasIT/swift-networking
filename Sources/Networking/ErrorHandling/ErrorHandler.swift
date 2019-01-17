//
// Created by Nikita Zatsepilov on 2019-01-15.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

import Alamofire

public protocol ErrorHandler {

    func canHandleError<T>(_ error: RequestError<T>) -> Bool
    func handleError<T>(_ error: RequestError<T>, completion: @escaping (ErrorHandlingResult) -> Void)
}
