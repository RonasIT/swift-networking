//
// Created by Nikita Zatsepilov on 2019-01-17.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

import Networking

protocol HasSessionService {

    var sessionService: SessionServiceProtocol { get }
}

protocol SessionServiceProtocol: Networking.SessionServiceProtocol {

    func updateToken(to token: String?)
}

protocol SessionServiceOutput: AnyObject {

    func sessionServiceDidStartTokenRefresh()
}
