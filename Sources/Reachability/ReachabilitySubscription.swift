//
// Created by Nikita Zatsepilov on 2019-01-24.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

import Foundation

public protocol ReachabilitySubscription: AnyObject {

    func unsubscribe()
}

final class NetworkReachabilitySubscription: ReachabilitySubscription {

    typealias UnsubscribeHandler = (String) -> Void
    typealias NotificationHandler = (Bool) -> Void

    let id: String = UUID().uuidString
    let unsubscribeHandler: UnsubscribeHandler
    let notificationHandler: NotificationHandler

    private var isActive: Bool = true

    init(unsubscribeHandler: @escaping UnsubscribeHandler, notificationHandler: @escaping NotificationHandler) {
        self.unsubscribeHandler = unsubscribeHandler
        self.notificationHandler = notificationHandler
    }

    func unsubscribe() {
        if isActive {
            unsubscribeHandler(id)
            isActive = false
        }
    }
}
