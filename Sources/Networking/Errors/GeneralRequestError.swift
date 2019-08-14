//
// Created by Nikita Zatsepilov on 2019-01-22.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

public enum GeneralRequestError: Error, Equatable {
    case noInternetConnection
    case timedOut
    case noAuth
    case forbidden
    case notFound
    case cancelled
}
