//
// Created by Nikita Zatsepilov on 2019-01-17.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

import Alamofire

public protocol CancellableRequest: AnyObject, Cancellable {

    var endpoint: Endpoint { get }
}

class BaseRequest<Result>: CancellableRequest, AdaptiveRequest, Retryable {

    typealias Completion = (DataResponse<Result>) -> Void

    public let endpoint: Endpoint

    let sessionManager: SessionManager
    let responseSerializer: DataResponseSerializer<Result>

    private(set) var headers: [RequestHeader]

    init(sessionManager: SessionManager = .default,
         endpoint: Endpoint,
         responseSerializer: DataResponseSerializer<Result>) {
        self.endpoint = endpoint
        self.sessionManager = sessionManager
        self.responseSerializer = responseSerializer
        headers = endpoint.headers
    }

    deinit {
        #warning("Remove logging")
        print("\(self) \(#function)")
    }

    func response(completion: @escaping Completion) {
        fatalError("\(#function) is abstract")
    }

    func retry() {
        fatalError("\(#function) is abstract")
    }

    func cancel() {
        fatalError("\(#function) is abstract")
    }

    func appendHeader(_ header: RequestHeader) {
        let indexOrNil = headers.firstIndex { $0.key == header.key }
        if let index = indexOrNil {
            headers.remove(at: index)
        }
        headers.append(header)
    }
}
