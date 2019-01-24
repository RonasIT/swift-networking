//
//  Created by Dmitry Frishbuter on 27/09/2018
//  Copyright © 2018 Ronas IT. All rights reserved.
//

import Alamofire

public class ReachabilityService: ReachabilityServiceProtocol {

    private lazy var reachabilityManager: NetworkReachabilityManager = NetworkReachabilityManager()!
    private lazy var subscriptions: [String: NetworkReachabilitySubscription] = [:]

    public var isReachable: Bool {
        return reachabilityManager.isReachable
    }

    public init() {}

    deinit {
        stopMonitoring()
    }

    public func subscribe(with handler: @escaping (Bool) -> Void) -> ReachabilitySubscription {
        let subscription = NetworkReachabilitySubscription(unsubscribeHandler: { [weak self] subscriptionId in
            self?.subscriptions[subscriptionId] = nil
        }, notificationHandler: handler)
        subscriptions[subscription.id] = subscription
        return subscription
    }

    public func startMonitoring() {
        reachabilityManager.listener = { [weak self] status in
            guard let `self` = self else {
                return
            }
            let isReachable = status.isReachable
            self.subscriptions.keys.forEach { key in
                self.subscriptions[key]?.notificationHandler(isReachable)
            }
        }
        reachabilityManager.startListening()
    }

    public func stopMonitoring() {
        reachabilityManager.stopListening()
    }
}

private extension NetworkReachabilityManager.NetworkReachabilityStatus {

    var isReachable: Bool {
        switch self {
        case .notReachable, .unknown:
            return false
        case .reachable:
            return true
        }
    }
}
