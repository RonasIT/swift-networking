//
//  Created by Dmitry Frishbuter on 27/09/2018
//  Copyright © 2018 Ronas IT. All rights reserved.
//

import Alamofire

class ReachabilityService {

    var handler: ((Bool) -> Void)?

    private let reachabilityManager = Alamofire.NetworkReachabilityManager()

    // MARK: - Reachable status

    var isReachable: Bool {
        return reachabilityManager!.isReachable
    }

    deinit {
        stopMonitoring()
    }

    // MARK: - Monitoring

    func startMonitoring() {
        reachabilityManager!.listener = { [weak self] status in
            guard let handler = self?.handler else {
                return
            }
            switch status {
            case .notReachable, .unknown:
                handler(false)
            case .reachable:
                handler(true)
            }
        }
        reachabilityManager!.startListening()
    }

    func stopMonitoring() {
        reachabilityManager!.stopListening()
    }
}
