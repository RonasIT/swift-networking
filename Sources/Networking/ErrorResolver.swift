//
// Created by Nikita Zatsepilov on 07/12/2018.
// Copyright (c) 2018 Ronas IT. All rights reserved.
//

import Foundation

public enum ErrorResolution {
    case failure
    case retryRequest
}

public protocol ErrorResolver {

    typealias Completion = (ErrorResolution) -> Void

    func canResolveError(_ error: Error) -> Bool
    func resolveError(_ error: Error, endpoint: Endpoint, completion: @escaping Completion)
}
