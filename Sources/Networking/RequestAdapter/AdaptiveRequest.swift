//
// Created by Nikita Zatsepilov on 06/12/2018.
// Copyright (c) 2018 Ronas IT. All rights reserved.
//

import Foundation

public final class AdaptiveRequest {

    private let request: NetworkRequest

    public var endpoint: Endpoint {
        return request.endpoint
    }

    init(request: NetworkRequest) {
        self.request = request
    }

    @discardableResult
    public func addHeader(_ header: RequestHeader) -> Self {
        request.addHeader(header)
        return self
    }
}
