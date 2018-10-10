//
//  Created by Dmitry Frishbuter on 27/09/2018
//  Copyright © 2018 Ronas IT. All rights reserved.
//

import Foundation
import Alamofire
import Networking

enum AnythingEndpoint: Endpoint {
    case fetchSlideshow
    case postContact(Contact)

    var baseURL: URL {
        return URL(string: "https://httpbin.org/")!
    }

    var path: String {
        switch self {
        case .fetchSlideshow:
            return "json"
        case .postContact:
            return "anything"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .fetchSlideshow: return .get
        case .postContact:    return .post
        }
    }

    var headers: [RequestHeader] {
        return []
    }

    var parameters: Parameters? {
        switch self {
        case .postContact(let contact):
            return try? contact.asDictionary()
        default:
            return nil
        }
    }

    var parameterEncoding: ParameterEncoding {
        return URLEncoding.default
    }
}

