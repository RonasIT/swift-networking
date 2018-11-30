//
// Created by Nikita Zatsepilov on 30/11/2018.
// Copyright (c) 2018 Ronas IT. All rights reserved.
//

import Foundation
import Alamofire

final class RequestFactory {

    private let sessionManager: SessionManager

    init(sessionManager: SessionManager = SessionManager.default) {
        self.sessionManager = sessionManager
    }

    func makeRequest(endpoint: Endpoint) -> Request {
        return GeneralRequest(endpoint: endpoint, sessionManager: sessionManager)
    }
}
