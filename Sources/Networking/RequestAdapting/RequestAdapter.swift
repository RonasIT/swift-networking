//
// Created by Nikita Zatsepilov on 06/12/2018.
// Copyright (c) 2018 Ronas IT. All rights reserved.
//

public protocol RequestAdapter {

    func adapt(_ request: AdaptiveRequest)
}

extension RequestAdapter {

    func adapt(_ request: Request) {
        adapt(request as AdaptiveRequest)
    }
}
