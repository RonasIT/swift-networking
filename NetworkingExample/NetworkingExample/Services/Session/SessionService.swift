//
// Created by Nikita Zatsepilov on 07/12/2018.
// Copyright (c) 2018 Ronas IT. All rights reserved.
//

import Foundation

protocol SessionServiceProtocol {

    func token() -> String?
}

final class SessionService: SessionServiceProtocol {

    func token() -> String? {
        return "any-token"
    }
}
