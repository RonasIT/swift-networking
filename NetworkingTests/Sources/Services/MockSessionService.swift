//
// Created by Nikita Zatsepilov on 2019-01-18.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

import Networking

final class MockSessionService: SessionServiceProtocol {

    enum Constants {
        static let validToken = "validToken"
        static let validAuthHeader = RequestHeaders.authorization(validToken)
    }

    typealias TokenRefreshCompletion = (String) -> Void
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
            // Token expires in 24 hours
            let expiryDate = Date(timeIntervalSinceNow: 24 * 60 * 60)
            self.token = AuthToken(token: token, expirationDate: expiryDate)
            success()
        }, { [weak self] error in
            self?.token = nil
            failure(error)
        })
    }
}

