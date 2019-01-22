//
// Created by Nikita Zatsepilov on 07/12/2018.
// Copyright (c) 2018 Ronas IT. All rights reserved.
//

import Alamofire
import Networking

final class SessionService: SessionServiceProtocol {

    weak var output: SessionServiceOutput?

    private var token: String?

    var authToken: String? {
        return nil
    }

    var refreshAuthToken: String? {
        // FIXME: update code
        return nil
    }

    func updateToken(to token: String?) {
        self.token = token
    }

    func refreshAuthToken(success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        output?.sessionServiceDidStartTokenRefresh()
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.updateToken(to: "token")
            failure(AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 401)))
        }
    }
}
