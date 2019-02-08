//
// Created by Nikita Zatsepilov on 2019-01-23.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

import Networking
import Alamofire

enum FailureEndpoint: UploadEndpoint {

    case failure
    case uploadFailure

    var baseURL: URL {
        return URL(string: "https://localhost")!
    }

    var path: String {
        return "failure"
    }

    var method: HTTPMethod {
        switch self {
        case .failure:
            return .get
        case .uploadFailure:
            return .post
        }
    }

    var headers: [RequestHeader] {
        return []
    }

    var parameters: Parameters? {
        switch self {
        case .uploadFailure:
            return [:]
        default:
            return nil
        }
    }

    var parameterEncoding: ParameterEncoding {
        return URLEncoding.default
    }

    var requiresAuthorization: Bool {
        return false
    }

    var imageBodyParts: [ImageBodyPart] {
        switch self {
        case .uploadFailure:
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
