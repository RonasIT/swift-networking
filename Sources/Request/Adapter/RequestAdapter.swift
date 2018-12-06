//
// Created by Nikita Zatsepilov on 06/12/2018.
// Copyright (c) 2018 Ronas IT. All rights reserved.
//

import Foundation

open class RequestAdapter {

    public init() {

    }

    func adapt(request: NetworkRequest) {
        adapt(request: request, customizer: RequestCustomizer(request: request))
    }

    open func adapt(request: Request, customizer: RequestCustomizer) {
        // FIXME: `Request` shouldn't be cancellable here
    }
}
