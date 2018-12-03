//
// Created by Nikita Zatsepilov on 03/12/2018.
// Copyright (c) 2018 Ronas IT. All rights reserved.
//

import Alamofire

protocol HTTPHeadersFactory: AnyObject {

    func httpHeaders(for request: BasicRequest) -> HTTPHeaders
}

final class GeneralHTTPHeadersFactory: HTTPHeadersFactory {

    func httpHeaders(for request: BasicRequest) -> HTTPHeaders {
        var headers = request.endpoint.headers
        switch request.auth {
        case .token(let token):
            headers.append(RequestHeaders.authorization(token))
        default:
            break
        }
        return headers.httpHeaders
    }
}
