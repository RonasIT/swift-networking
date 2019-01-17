//
//  Created by Dmitry Frishbuter on 27/09/2018
//  Copyright © 2018 Ronas IT. All rights reserved.
//

import Foundation
import Alamofire
import Networking

enum ApiEndpoint: Endpoint {
    case json
    case anything(Codable)
    case bearer

    var baseURL: URL {
        return URL(string: "https://httpbin.org/")!
    }

    var path: String {
        switch self {
        case .anything, .json:  return "anything"
        case .bearer:           return "bearer"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .bearer, .json:
            return .get
        case .anything:
            return .post
        }
    }

    var headers: [RequestHeader] {
        return []
    }

    var parameters: Parameters? {
        switch self {
        case .anything(let object):
            return try? object.asDictionary()
        default:
            return nil
        }
    }

    var parameterEncoding: ParameterEncoding {
        return URLEncoding.default
    }
}

