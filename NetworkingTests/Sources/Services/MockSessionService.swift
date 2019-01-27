//
// Created by Nikita Zatsepilov on 2019-01-18.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

import Networking

final class MockSessionService: SessionServiceProtocol {

    enum Constants {
        // Token expires in 24 hours
        static let validAuthToken = AuthToken(token: "token", expirationDate: Date(timeIntervalSinceNow: 24 * 60 * 60))
    }

    typealias TokenRefreshCompletion = (AuthToken) -> Void
    typealias TokenRefreshFailure = (Error) -> Void
    
    private var token: AuthToken?

    var tokenRefreshHandler: ((TokenRefreshCompletion?, TokenRefreshFailure?) -> Void)?

    var authToken: AuthToken? {
        return token
    }

    func clearToken() {
        token = nil
    }

    func refreshAuthToken(success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
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

