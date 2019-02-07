//
// Created by Nikita Zatsepilov on 2019-01-17.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

public final class TokenRequestAdapter: RequestAdapter {

    private let accessTokenSupervisor: AccessTokenSupervisor

    public init(accessTokenSupervisor: AccessTokenSupervisor) {
        self.accessTokenSupervisor = accessTokenSupervisor
    }

    public func adapt(_ request: AdaptiveRequest) {
        if request.endpoint.requiresAuthorization, let accessToken = accessTokenSupervisor.accessToken {
            request.appendHeader(RequestHeaders.authorization(accessToken))
        }
    }
}
