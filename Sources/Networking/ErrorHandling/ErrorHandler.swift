//
// Created by Nikita Zatsepilov on 2019-01-15.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

import Alamofire

public protocol ErrorHandler: AnyObject {
    typealias Completion = (ErrorHandlingResult) -> Void
    func handleError<T>(_ requestError: RequestError<T>, completion: @escaping Completion)
}
