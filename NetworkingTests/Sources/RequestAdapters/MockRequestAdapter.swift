//
// Created by Nikita Zatsepilov on 2019-01-18.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

import Networking

final class MockRequestAdapter: RequestAdapter {

    var adapting: ((MutableRequest) -> Void)?

    func adapt(_ request: AdaptiveRequest) {
        adapting?(request)
    }
}
