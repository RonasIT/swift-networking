//
//  Created by Dmitry Frishbuter on 27/09/2018
//  Copyright © 2018 Ronas IT. All rights reserved.
//

import Foundation
import Alamofire
import Networking

enum AnythingEndpoint: Endpoint {
    case fetchData(Contact)
    case postData(Contact)

    var baseURL: URL {
        return URL(string: "https://httpbin.org/")!
    }

    var path: String {
        return "anything"
    }

    var method: HTTPMethod {
        switch self {
        case .fetchData:  return .get
        case .postData:   return .post
        }
    }

    var headers: [RequestHeader] {
        return []
    }

    var parameters: Parameters? {
        switch self {
        case .fetchData(let contact):
            return try? contact.asDictionary()
        case .postData(let contact):
            return try? contact.asDictionary()
        }
    }

    var parameterEncoding: ParameterEncoding {
        return URLEncoding.default
    }
}

