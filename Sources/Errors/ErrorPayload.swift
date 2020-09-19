//
//  Created by Dmitry Frishbuter on 20.08.2020
//  Copyright © 2020 Ronas IT. All rights reserved.
//

import Foundation
import Alamofire

public final class ErrorPayload {
    public let endpoint: Endpoint
    public let error: Error
    public let response: AFDataResponse<Data>

    var statusCode: StatusCode? {
        guard let response = response.response else {
            return nil
        }
        return StatusCode(rawValue: response.statusCode)
    }

    init(endpoint: Endpoint, error: Error, response: AFDataResponse<Data>) {
        self.endpoint = endpoint
        self.error = error
        self.response = response
    }
}

// MARK: -  CustomStringConvertible

extension ErrorPayload: CustomStringConvertible {

    public var description: String {
        let pointerString = "\(Unmanaged.passUnretained(self).toOpaque())"
        return """
               <RequestError:\(pointerString)> \
               from `/\(endpoint.path)` [\(endpoint.method.rawValue.uppercased())]
               """
    }
}
