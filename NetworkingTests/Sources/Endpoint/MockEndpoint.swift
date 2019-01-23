//
// Created by Nikita Zatsepilov on 2019-01-23.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

import Alamofire
import Networking

enum MockEndpoint: UploadEndpoint {
    case success
    case successUpload
    case failure
    case authorized
    case headersValidation([RequestHeader])

    var baseURL: URL {
        return URL(string: "localhost")!
    }

    var path: String {
        return "mock"
    }

    var method: HTTPMethod {
        switch self {
        case .successUpload:
            return .post
        default:
            return .get
        }
    }

    var headers: [RequestHeader] {
        return []
    }

    var parameters: Parameters? {
        return nil
    }

    var parameterEncoding: ParameterEncoding {
        return URLEncoding.default
    }

    var isAuthorized: Bool {
        switch self {
        case .authorized:
            return true
        default:
            return false
        }
    }
}
