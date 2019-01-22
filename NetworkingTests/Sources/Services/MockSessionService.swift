//
// Created by Nikita Zatsepilov on 2019-01-18.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

import Networking

final class MockSessionService: SessionServiceProtocol {

    typealias TokenRefreshCompletion = (String) -> Void
    typealias TokenRefreshFailure = (Error) -> Void
    
    private var token: String?

    var tokenRefreshHandler: ((TokenRefreshCompletion?, TokenRefreshFailure?) -> Void)?

    var authToken: String? {
        return token
    }

    var refreshAuthToken: String? {
        // FIXME: correct
        return nil
    }

    func clearToken() {
        token = nil
    }

    func refreshAuthToken(success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        tokenRefreshHandler?({ [weak self] token in
            self?.token = token
            success()
        }, { [weak self] error in
            self?.token = nil
            failure(error)
        })
    }
}

