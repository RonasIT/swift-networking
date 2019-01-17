//
// Created by Nikita Zatsepilov on 2019-01-17.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

public class TokenRequestAdapter: RequestAdapter {

    private let sessionService: SessionServiceProtocol

    public init(sessionService: SessionServiceProtocol) {
        self.sessionService = sessionService
    }

    public func adapt(_ request: AdaptiveRequest) {
        if let token = sessionService.authToken {
            request.appendHeader(RequestHeaders.authorization(token))
        }
    }
}
