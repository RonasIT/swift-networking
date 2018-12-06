//
// Created by Nikita Zatsepilov on 06/12/2018.
// Copyright (c) 2018 Ronas IT. All rights reserved.
//

import Foundation

public final class RequestCustomizer {

    private let request: NetworkRequest

    init(request: NetworkRequest) {
        self.request = request
    }

    public func addHeader(_ header: RequestHeader) -> Self {
        request.addHeader(header)
        return self
    }
}
