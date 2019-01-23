//
// Created by Nikita Zatsepilov on 2019-01-23.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

import Networking
import Alamofire

enum HTTPBinEndpoint: UploadEndpoint {

    case status(Int)
    case uploadStatus(Int)

    var baseURL: URL {
        return URL(string: "https://httpbin.org/")!
    }

    var path: String {
        switch self {
        case .status(let status):
            return "/status/\(status)"
        case .uploadStatus(let status):
            return "/status/\(status)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .status:
            return .get
        case .uploadStatus:
            return .post
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
        return false
    }

    var imageBodyParts: [ImageBodyPart] {
        switch self {
        case .uploadStatus:
            let base64Encoded = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=="
            guard let imageData = Data(base64Encoded: base64Encoded) else {
                return []
            }
            return [ImageBodyPart(imageData: imageData)]
        default:
            return []
        }
    }
}
