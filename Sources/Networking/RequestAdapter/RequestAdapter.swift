//
// Created by Nikita Zatsepilov on 06/12/2018.
// Copyright (c) 2018 Ronas IT. All rights reserved.
//

import Foundation

public protocol RequestAdapter {

    func adaptRequest(_ request: AdaptiveRequest)
}

extension RequestAdapter {

    func adaptRequest(_ request: NetworkRequest) {
        adaptRequest(AdaptiveRequest(request: request))
    }
}
