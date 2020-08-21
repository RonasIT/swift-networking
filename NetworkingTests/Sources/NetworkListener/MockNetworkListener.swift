//
// Created by Nikita Zatsepilov on 2019-01-31.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

@testable import Networking
import Alamofire

final class MockNetworkListener: NetworkListener {

    var listener: Listener?

    var isReachable: Bool = false {
        didSet {
            let status: NetworkReachabilityStatus = isReachable ? .reachable(.ethernetOrWiFi) : .notReachable
            listener?(status)
        }
    }

    @discardableResult
    func startListening(onQueue queue: DispatchQueue, onUpdatePerforming listener: @escaping Listener) -> Bool {
        return true
    }

    func stopListening() {
        listener = nil
    }
}
