//
//  Created by Dmitry Frishbuter on 27/09/2018
//  Copyright © 2018 Ronas IT. All rights reserved.
//

import Alamofire

public typealias CancellableRequest = BasicRequest & Cancellable

public protocol Cancellable {

    func cancel()
}

public protocol Retryable {

    func retry()
}

public protocol BasicRequest: AnyObject {

    var id: String { get }
    var endpoint: Endpoint { get }
}
