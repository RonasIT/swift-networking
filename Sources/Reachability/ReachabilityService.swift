//
//  Created by Dmitry Frishbuter on 27/09/2018
//  Copyright © 2018 Ronas IT. All rights reserved.
//

import Alamofire

typealias NetworkReachabilityStatus = NetworkReachabilityManager.NetworkReachabilityStatus

public class ReachabilityService: ReachabilityServiceProtocol {

    public var isReachable: Bool {
        return networkListener.isReachable
    }

    private let networkListener: NetworkListener
    private var subscriptions: [String: NetworkReachabilitySubscription] = [:]

    init(networkListener: NetworkListener) {
        self.networkListener = networkListener
    }

    convenience public init() {
        let networkListener: NetworkListener = NetworkReachabilityManager()!
        self.init(networkListener: networkListener)
    }

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
        networkListener.startListening { [weak self] isReachable in
            self?.notifySubscribers(isNetworkReachable: isReachable)
        }
    }

    public func stopMonitoring() {
        networkListener.stopListening()
    }

    // MARK: - Private

    private func notifySubscribers(isNetworkReachable: Bool) {
        subscriptions.keys.forEach { key in
            subscriptions[key]?.notificationHandler(isReachable)
        }
    }
}
