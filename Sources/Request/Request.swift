//
//  Created by Dmitry Frishbuter on 27/09/2018
//  Copyright © 2018 Ronas IT. All rights reserved.
//

import Alamofire

public typealias Request = BasicRequest & CancellableRequest

public protocol CancellableRequest {

    func cancel()
}

public protocol BasicRequest: AnyObject {

    var endpoint: Endpoint { get }
}
