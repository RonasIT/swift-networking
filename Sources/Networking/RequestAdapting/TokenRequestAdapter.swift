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
        guard request.endpoint.isAuthorized,
              let header = sessionService.authTokenHeader else {
            return
        }
        request.appendHeader(header)
    }

    func adaptForRetry(_ request: AdaptiveRequest) {
        guard request.endpoint.isAuthorized,
              let header = sessionService.refreshAuthTokenHeader else {
            return
        }
        request.appendHeader(header)
    }
}
