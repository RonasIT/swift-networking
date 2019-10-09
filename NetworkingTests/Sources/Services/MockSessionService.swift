//
// Created by Nikita Zatsepilov on 2019-01-18.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

import Networking

final class MockSessionService: AccessTokenSupervisor {

    enum Constants {
        static let invalidAccessToken = "invalidToken"
        static let validAccessToken = "token"
    }

    typealias TokenRefreshCompletion = (String) -> Void
    typealias TokenRefreshFailure = (Error) -> Void

    private var token: String? = Constants.invalidAccessToken

    var tokenRefreshHandler: ((TokenRefreshCompletion?, TokenRefreshFailure?) -> Void)?

    var accessToken: String? {
        return token
    }

    func updateToken(to newToken: String?) {
        token = newToken
    }

    func refreshAccessToken(success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        tokenRefreshHandler?({ [weak self] token in
            guard let self = self else {
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
