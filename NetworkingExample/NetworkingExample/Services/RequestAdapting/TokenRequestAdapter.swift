//
// Created by Nikita Zatsepilov on 07/12/2018.
// Copyright (c) 2018 Ronas IT. All rights reserved.
//

import Networking

final class TokenRequestAdapter: RequestAdapter {

    private let sessionService: SessionServiceProtocol

    init(sessionService: SessionServiceProtocol) {
        self.sessionService = sessionService
    }

    func adapt(_ request: AdaptiveRequest) {
        if let token = sessionService.token() {
            request.append(RequestHeaders.authorization(token))
        }
    }
}
