//
// Created by Nikita Zatsepilov on 03/12/2018.
// Copyright (c) 2018 Ronas IT. All rights reserved.
//

import Alamofire

public protocol HTTPHeadersFactory: AnyObject {

    func httpHeaders(for request: Request) -> HTTPHeaders
}

open class GeneralHTTPHeadersFactory: HTTPHeadersFactory {

    // TODO: find way to avoid empty init
    public init() {

    }

     public func httpHeaders(for request: Request) -> HTTPHeaders {
        var headers = request.endpoint.headers
        switch request.authorization {
        case .token(let token):
            headers.append(RequestHeaders.authorization(token))
        case .none:
            break
        }
        return headers.httpHeaders
    }
}
