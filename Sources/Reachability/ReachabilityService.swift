//
//  Created by Dmitry Frishbuter on 27/09/2018
//  Copyright © 2018 Ronas IT. All rights reserved.
//

import Foundation
import Alamofire
import Combine

protocol NetworkListener: AnyObject {
    typealias Listener = NetworkReachabilityManager.Listener

    var isReachable: Bool { get }

    @discardableResult
    func startListening(onQueue queue: DispatchQueue,
                        onUpdatePerforming listener: @escaping Listener) -> Bool
    func stopListening()
}

public typealias NetworkReachabilityStatus = NetworkReachabilityManager.NetworkReachabilityStatus

public final class ReachabilityService: ReachabilityServiceProtocol {

    public var isReachable: Bool {
        return networkListener.isReachable
    }

    public let reachabilityStatusSubject: PassthroughSubject<NetworkReachabilityStatus, Never> = .init()

    private let networkListener: NetworkListener

    init(networkListener: NetworkListener) {
        self.networkListener = networkListener
    }

    convenience public init(host: String? = nil) {
        if let host = host {
            self.init(networkListener: NetworkReachabilityManager(host: host)!)
        } else {
            self.init(networkListener: NetworkReachabilityManager()!)
        }
    }

    deinit {
        stopMonitoring()
    }

    public func startMonitoring() {
        networkListener.startListening(onQueue: .main) { [weak self] reachabilityStatus in
            self?.reachabilityStatusSubject.send(reachabilityStatus)
        }
    }

    public func stopMonitoring() {
        networkListener.stopListening()
    }
}

extension NetworkReachabilityManager: NetworkListener {}

public extension NetworkReachabilityStatus {

    var isReachable: Bool {
        switch self {
        case .reachable:
            return true
        case .unknown, .notReachable:
            return false
        }
    }
}
