//
// Created by Nikita Zatsepilov on 2019-01-17.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

import Foundation

public final class AuthToken {

    let token: String

    // Expiration date provides token validation
    // For example, to trigger token refreshing, we must be sure, that current token is not valid
    // Otherwise token refreshing may be triggered multiple times
    let expirationDate: Date

    public init(token: String, expirationDate: Date) {
        self.token = token
        self.expirationDate = expirationDate
    }
}

public protocol SessionServiceProtocol {

    var authToken: AuthToken? { get }

    func refreshAuthToken(success: @escaping () -> Void, failure: @escaping (Error) -> Void)
}
