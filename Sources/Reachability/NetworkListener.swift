//
// Created by Nikita Zatsepilov on 2019-01-31.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

import Alamofire

protocol NetworkListener: AnyObject {
    typealias Listener = NetworkReachabilityManager.Listener

    var isReachable: Bool { get }

    @discardableResult
    func startListening(onQueue queue: DispatchQueue,
                        onUpdatePerforming listener: @escaping Listener) -> Bool
    func stopListening()
}
