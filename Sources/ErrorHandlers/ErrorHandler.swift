//
// Created by Nikita Zatsepilov on 2019-01-15.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

import Alamofire

public protocol ErrorHandler: AnyObject {
    typealias Completion = (ErrorHandlingResult) -> Void
    func handleError(_ requestError: RequestError, completion: @escaping Completion)
}
