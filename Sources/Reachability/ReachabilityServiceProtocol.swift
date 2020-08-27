//
//  Created by Dmitry Frishbuter on 27/09/2018
//  Copyright © 2018 Ronas IT. All rights reserved.
//

import Combine

public protocol HasReachabilityService {
    var reachabilityService: ReachabilityServiceProtocol { get }
}

public protocol ReachabilityServiceProtocol {
    var isReachable: Bool { get }
    var reachabilityStatusSubject: PassthroughSubject<NetworkReachabilityStatus, Never> { get }

    func startMonitoring()
    func stopMonitoring()
}
