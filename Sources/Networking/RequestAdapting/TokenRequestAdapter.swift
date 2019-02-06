//
// Created by Nikita Zatsepilov on 2019-01-17.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

public final class TokenRequestAdapter: RequestAdapter {

    private let sessionService: AccessTokenSupervisor

    public init(sessionService: AccessTokenSupervisor) {
        self.sessionService = sessionService
    }

    public func adapt(_ request: AdaptiveRequest) {
        if request.endpoint.requiresAuthorization, let accessToken = sessionService.accessToken {
            request.appendHeader(RequestHeaders.authorization(accessToken))
        }
    }
}
