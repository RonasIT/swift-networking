//
// Created by Nikita Zatsepilov on 2019-01-26.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

import Alamofire

class Request<Result>: BasicRequest, Cancellable, Retryable {

    typealias Completion = (RetryableRequest, DataResponse<Result>) -> Void

    public final let endpoint: Endpoint

    final let sessionManager: SessionManager
    final let responseSerializer: DataResponseSerializer<Result>

    private(set) final var headers: [RequestHeader]

    private var sentRequest: DataRequest?
    private var completion: Completion?

    init(sessionManager: SessionManager,
         endpoint: Endpoint,
         responseSerializer: DataResponseSerializer<Result>) {
        self.endpoint = endpoint
        self.sessionManager = sessionManager
        self.responseSerializer = responseSerializer
        headers = endpoint.headers
    }

    func response(completion: @escaping Completion) {
        self.completion = completion
        sentRequest = sessionManager.request(
            endpoint.url,
            method: endpoint.method,
            parameters: endpoint.parameters,
            encoding: endpoint.parameterEncoding,
            headers: headers.httpHeaders
        ).validate()
        sentRequest?.response(responseSerializer: responseSerializer) { response in
            self.completion?(self, response)
        }
    }

    // MARK: - Cancellable

    @discardableResult
    func cancel() -> Bool {
        guard let request = sentRequest else {
            return false
        }
        request.cancel()
        sentRequest = nil
        return true
    }

    // MARK: - Retryable

    @discardableResult
    func retry() -> Bool {
        guard let completion = completion else {
            return false
        }
        response(completion: completion)
        return true
    }
}

// MARK: - MutableRequest

extension Request: MutableRequest {
    
    func appendHeader(_ header: RequestHeader) {
        let indexOrNil = headers.firstIndex { $0.key == header.key }
        if let index = indexOrNil {
            headers.remove(at: index)
        }
        headers.append(header)
    }
}
