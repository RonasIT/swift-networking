//
// Created by Nikita Zatsepilov on 09/12/2018.
// Copyright (c) 2018 Ronas IT. All rights reserved.
//

public protocol RequestAdaptingServiceProtocol {

    func adapt(_ request: AdaptiveRequest)
}

open class RequestAdaptingService: RequestAdaptingServiceProtocol {

    private let requestAdapters: [RequestAdapter]

    public init(requestAdapters: [RequestAdapter]) {
        self.requestAdapters = requestAdapters
    }

    public func adapt(_ request: AdaptiveRequest) {
        requestAdapters.forEach { $0.adapt(request) }
    }
}
