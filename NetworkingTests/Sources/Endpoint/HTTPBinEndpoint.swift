//
// Created by Nikita Zatsepilov on 2019-01-18.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

import Networking
import Alamofire

private extension Encodable {

    func asDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        guard let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
            throw NSError()
        }
        return dictionary
    }
}

enum HTTPBinEndpoint: UploadEndpoint {
    /// https://httpbin.org/#/Auth/get_bearer
    case bearer
    /// https://httpbin.org/#/Anything/get_anything
    case anythingEncodable(Encodable)
    /// https://httpbin.org/#/Anything/get_anything
    case anythingJSON([String: Any])
    /// https://httpbin.org/#/Status_codes/get_status__codes_
    case status(Int)
    /// https://httpbin.org/#/Dynamic_data/get_delay__delay_
    case delay(Int)
    /// POST to https://httpbin.org/#/Status_codes/get_status__codes_
    case upload

    var baseURL: URL {
        return URL(string: "https://httpbin.org/")!
    }

    var path: String {
        switch self {
        case .anythingJSON,
             .anythingEncodable:
            return "anything"
        case .bearer:
            return "bearer"
        case .status(let statusCode):
            return "status/\(statusCode)"
        case .delay(let delay):
            return "delay/\(delay)"
        case .upload:
            return "status/200"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .anythingJSON,
             .anythingEncodable,
             .bearer,
             .status,
             .delay:
            return .get
        case .upload:
            return .post
        }
    }

    var headers: [RequestHeader] {
        return []
    }

    var parameters: Parameters? {
        switch self {
        case .anythingEncodable(let object):
            return try? object.asDictionary()
        case .anythingJSON(let json):
            return json
        default:
            return nil
        }
    }

    var parameterEncoding: ParameterEncoding {
        return URLEncoding.default
    }

    var imageBodyParts: [ImageBodyPart] {
        switch self {
        case .upload:
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
