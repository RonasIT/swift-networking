//
// Created by Nikita Zatsepilov on 2019-01-17.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

public protocol AccessTokenSupervisor {
    var accessToken: String? { get }
    func refreshAccessToken(success: @escaping () -> Void, failure: @escaping (Error) -> Void)
}
