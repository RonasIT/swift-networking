//
// Created by Nikita Zatsepilov on 2019-01-26.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

import Alamofire

class Request<Result>: BasicRequest, MutableRequest, Cancellable, Retryable {

    typealias Completion = (DataResponse<Result>) -> Void

    public let endpoint: Endpoint

    let sessionManager: SessionManager
    let responseSerializer: DataResponseSerializer<Result>

    private(set) var headers: [RequestHeader]

    private var request: DataRequest?
    private var completion: Completion?

    init(sessionManager: SessionManager,
         endpoint: Endpoint,
         responseSerializer: DataResponseSerializer<Result>) {
        self.endpoint = endpoint
        self.sessionManager = sessionManager
        self.responseSerializer = responseSerializer
        headers = endpoint.headers
    }

    func response(completion: @escaping (DataResponse<Result>) -> Void) {
        self.completion = completion
        request = sessionManager.request(endpoint.url,
                                         method: endpoint.method,
                                         parameters: endpoint.parameters,
                                         encoding: endpoint.parameterEncoding,
                                         headers: headers.httpHeaders).validate()
        request?.response(responseSerializer: responseSerializer, completionHandler: completion)
    }

    func cancel() {
        request?.cancel()
    }

    func retry() {
        if let completion = completion {
            response(completion: completion)
        }
    }

    func appendHeader(_ header: RequestHeader) {
        let indexOrNil = headers.firstIndex { $0.key == header.key }
        if let index = indexOrNil {
            headers.remove(at: index)
        }
        headers.append(header)
    }
}
