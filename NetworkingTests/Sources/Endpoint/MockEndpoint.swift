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
    case mappedErrorForURLErrorCode(URLError.Code, mappedError: Error)
    case mappedErrorForResponseCode(Int, mappedError: Error)
    case headersValidation([RequestHeader])
    case urlValidation(baseURL: URL, path: String)

    var baseURL: URL {
        switch self {
        case .urlValidation(baseURL: let baseURL, path: _):
            return baseURL
        default:
            return URL(string: "localhost")!
        }
    }

    var path: String {
        switch self {
        case .urlValidation(baseURL: _, path: let path):
            return path
        default:
            return "mock"
        }
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

    var requiresAuthorization: Bool {
        switch self {
        case .authorized:
            return true
        default:
            return false
        }
    }

    func error(forResponseCode responseCode: Int) -> Error? {
        let receivedResponseCode = responseCode
        switch self {
        case .mappedErrorForResponseCode(let responseCode, mappedError: let error):
            if responseCode == receivedResponseCode {
                return error
            }
        default:
            return nil
        }
        return nil
    }

    func error(for urlErrorCode: URLError.Code) -> Error? {
        let receivedURLErrorCode = urlErrorCode
        switch self {
        case .mappedErrorForURLErrorCode(let urlErrorCode, mappedError: let error):
            if urlErrorCode == receivedURLErrorCode {
                return error
            }
        default:
            return nil
        }
        return nil
    }
}
