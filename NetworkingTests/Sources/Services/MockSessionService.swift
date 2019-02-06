//
// Created by Nikita Zatsepilov on 2019-01-18.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

import Networking

final class MockSessionService: AccessTokenSupervisor {

    enum Constants {
        // Token expires in 24 hours
        static let validAccessToken = AccessToken(token: "token", expirationDate: Date(timeIntervalSinceNow: 24 * 60 * 60))
    }

    typealias TokenRefreshCompletion = (AccessToken) -> Void
    typealias TokenRefreshFailure = (Error) -> Void
    
    private var token: AccessToken?

    var tokenRefreshHandler: ((TokenRefreshCompletion?, TokenRefreshFailure?) -> Void)?

    var accessToken: AccessToken? {
        return token
    }

    func clearToken() {
        token = nil
    }

    func refreshAccessToken(success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        tokenRefreshHandler?({ [weak self] token in
            guard let `self` = self else {
                return
            }
            self.token = token
            success()
        }, { [weak self] error in
            self?.token = nil
            failure(error)
        })
    }
}
