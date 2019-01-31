//
// Created by Nikita Zatsepilov on 2019-01-31.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

protocol NetworkListener: AnyObject {

    typealias NotificationHandler = (Bool) -> Void

    var isReachable: Bool { get }

    func startListening(with notificationHandler: @escaping NotificationHandler)
    func stopListening()
}
