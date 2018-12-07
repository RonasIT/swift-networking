//
// Created by Nikita Zatsepilov on 06/12/2018.
// Copyright (c) 2018 Ronas IT. All rights reserved.
//

import Foundation

open class RequestAdapter {

    public init() {

    }

    open func adaptRequest(_ request: AdaptiveRequest) {

    }

    func adaptRequest(_ request: NetworkRequest) {
        adaptRequest(AdaptiveRequest(request: request))
    }
}
