//
// Created by Nikita Zatsepilov on 2019-01-15.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

import Alamofire

public protocol ErrorHandler {

    func canHandleError(_ error: Error) -> Bool
    func handleError(_ error: Error, completion: @escaping (ErrorHandlingResult) -> Void)
}
