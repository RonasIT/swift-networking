//
// Created by Nikita Zatsepilov on 2019-01-31.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

@testable import Networking

final class MockNetworkListener: NetworkListener {

    private var notificationHandler: NotificationHandler?

    var isReachable: Bool = false {
        didSet {
            notificationHandler?(isReachable)
        }
    }

    func stopListening() {
        notificationHandler = nil
    }

    func startListening(with notificationHandler: @escaping NotificationHandler) {
        self.notificationHandler = notificationHandler
    }
}
