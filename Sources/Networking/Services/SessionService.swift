//
// Created by Nikita Zatsepilov on 2019-01-17.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

import Foundation

public final class AuthToken {

    let token: String
    let expiryDate: Date

    public init(token: String, expiryDate: Date) {
        self.token = token
        self.expiryDate = expiryDate
    }
}

public protocol SessionServiceProtocol {

    var authToken: AuthToken? { get }

    func refreshAuthToken(success: @escaping () -> Void, failure: @escaping (Error) -> Void)
}
