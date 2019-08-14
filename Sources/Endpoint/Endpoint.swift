//
//  Created by Dmitry Frishbuter on 27/09/2018
//  Copyright © 2018 Ronas IT. All rights reserved.
//

import Alamofire
import UIKit.UIDevice

public protocol Endpoint: EndpointError {
    var baseURL: URL { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [RequestHeader] { get }
    var parameters: Parameters? { get }
    var parameterEncoding: ParameterEncoding { get }
    var requiresAuthorization: Bool { get }
}

public protocol RequestHeader {
    var key: String { get }
    var value: String { get }
}

public enum RequestHeaders: RequestHeader {

    case authorization(String)
    case contentType(String)
    case accept(String)
    case userAgent(osVersion: String, appVersion: String)
    case dpi(scale: CGFloat)

    public var key: String {
        switch self {
        case .authorization:
            return "Authorization"
        case .contentType:
            return "Content-Type"
        case .accept:
            return "Accept"
        case .userAgent:
            return "User-Agent"
        case .dpi:
            return "dpi"
        }
    }

    public var value: String {
        switch self {
        case let .authorization(token):
            return "Bearer \(token)"
        case let .contentType(type):
            return type
        case let .accept(value):
            return value
        case let .userAgent(osVersion, appVersion):
            return "iOS \(osVersion) version \(appVersion)"
        case let .dpi(scale):
            return "@\(Int(scale))x"
        }
    }
}

public extension Endpoint {

    var url: URL {
        return baseURL + path
    }

    func error(forResponseCode responseCode: Int) -> Error? {
        return nil
    }

    func error(for urlErrorCode: URLError.Code) -> Error? {
        return nil
    }
}

public extension Collection where Iterator.Element == RequestHeader {

    var httpHeaders: HTTPHeaders {
        return reduce(into: HTTPHeaders()) { headers, element in
            headers[element.key] = element.value
        }
    }
}
