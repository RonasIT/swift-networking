//
// Created by Nikita Zatsepilov on 06/12/2018.
// Copyright (c) 2018 Ronas IT. All rights reserved.
//

import Foundation

public protocol RequestAuthorizationService: AnyObject {

    func authorization(for endpoint: Endpoint) -> RequestAuthorization
}

open class GeneralRequestAuthorizationService: RequestAuthorizationService {

    public init() {

    }

    public func authorization(for endpoint: Endpoint) -> RequestAuthorization {
        return .none
    }
}
