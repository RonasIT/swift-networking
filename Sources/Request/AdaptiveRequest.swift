//
// Created by Nikita Zatsepilov on 09/12/2018.
// Copyright (c) 2018 Ronas IT. All rights reserved.
//

public protocol AdaptiveRequest {

    var endpoint: Endpoint { get }
    var headers: [RequestHeader] { get }

    func appendHeader(_ header: RequestHeader)
}

