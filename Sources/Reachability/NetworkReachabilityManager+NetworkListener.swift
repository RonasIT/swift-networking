//
// Created by Nikita Zatsepilov on 2019-02-01.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

import Alamofire

extension NetworkReachabilityManager: NetworkListener {

    func startListening(with notificationHandler: @escaping NotificationHandler) {
        listener = { reachabilityStatus in
            notificationHandler(reachabilityStatus.isReachable)
        }
        startListening()
    }
}

private extension NetworkReachabilityStatus {

    var isReachable: Bool {
        switch self {
        case .notReachable, .unknown:
            return false
        case .reachable:
            return true
        }
    }
}
