//
// Created by Nikita Zatsepilov on 07/12/2018.
// Copyright (c) 2018 Ronas IT. All rights reserved.
//

import Foundation

protocol HasSessionService {

    var sessionService: SessionServiceProtocol { get }
}

protocol SessionServiceProtocol {

    func token() -> String?
    func refreshToken(completion: @escaping (Bool) -> Void)
}

final class SessionService: SessionServiceProtocol {

    func token() -> String? {
        return "any-token"
    }

    func refreshToken(completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            completion(false)
        }
    }
}
