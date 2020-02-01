//
//  Created by Dmitry Frishbuter on 27/09/2018
//  Copyright © 2018 Ronas IT. All rights reserved.
//

import Alamofire

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

public extension Endpoint {

    var url: URL {
        return baseURL + path
    }

    func error(forStatusCode statusCode: Int) -> Error? {
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
