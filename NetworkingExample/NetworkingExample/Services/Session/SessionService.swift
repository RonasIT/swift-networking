//
// Created by Nikita Zatsepilov on 07/12/2018.
// Copyright (c) 2018 Ronas IT. All rights reserved.
//

import Alamofire
import Networking

final class SessionService: SessionServiceProtocol {

    private var token: AccessToken?

    var accessToken: AccessToken? {
        return token
    }

    func refreshAccessToken(success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            // token will be valid next 24 hours
            let expirationDate = Date(timeIntervalSinceNow: 24 * 60 * 60)
            self?.token = AccessToken(token: "token", expirationDate: expirationDate)
        }
    }
}
