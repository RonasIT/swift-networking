//
// Created by Nikita Zatsepilov on 07/12/2018.
// Copyright (c) 2018 Ronas IT. All rights reserved.
//

import Alamofire
import Networking

final class SessionService: SessionServiceProtocol {

    private var token: String? = "invalidToken"

    var accessToken: String? {
        return token
    }

    func refreshAccessToken(success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.token = "token"
        }
    }
}
