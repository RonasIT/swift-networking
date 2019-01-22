//
// Created by Nikita Zatsepilov on 2019-01-17.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

public protocol SessionServiceProtocol {

    var authToken: String? { get }
    var refreshAuthToken: String? { get }

    func refreshAuthToken(success: @escaping () -> Void, failure: @escaping (Error) -> Void)
}

public extension SessionServiceProtocol {

    var authTokenHeader: RequestHeader? {
        guard let authToken = authToken else {
            return nil
        }
        return RequestHeaders.authorization(authToken)
    }
    
    var refreshAuthTokenHeader: RequestHeader? {
        return nil
    }
}