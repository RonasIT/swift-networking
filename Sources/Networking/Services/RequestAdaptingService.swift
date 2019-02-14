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

    public final func adapt(_ request: AdaptiveRequest) {
        Logging.log(
            type: .debug,
            category: .requestAdapting,
            "\(request) - Starting request adapting, found \(requestAdapters.count) adapters"
        )
        requestAdapters.forEach { requestAdapter in
            Logging.log(type: .debug, category: .requestAdapting, "\(request) - Adapting with \(requestAdapter)")
            requestAdapter.adapt(request)
        }
    }
}
