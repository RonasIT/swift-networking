//
// Created by Nikita Zatsepilov on 2019-01-26.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

import Alamofire

class Request: BasicRequest, Cancellable, Retryable {
    typealias Response = AFDataResponse<Data>
    typealias Completion = (RetryableRequest, Response) -> Void

    public final let endpoint: Endpoint

    final let session: Alamofire.Session

    private(set) final var headers: [RequestHeader]

    private var sentRequest: DataRequest?
    private var completion: Completion?

    init(session: Alamofire.Session, endpoint: Endpoint) {
        self.endpoint = endpoint
        self.session = session
        headers = endpoint.headers
    }

    func response(completion: @escaping Completion) {
        self.completion = completion
        sentRequest = session.request(
            endpoint.url,
            method: endpoint.method,
            parameters: endpoint.parameters,
            encoding: endpoint.parameterEncoding,
            headers: headers.httpHeaders
        ).validate()
        sentRequest?.responseData { (response: AFDataResponse<Data>) in
            self.completion?(self, response)
        }
    }

    // MARK: -  Cancellable

    @discardableResult
    func cancel() -> Bool {
        guard let request = sentRequest else {
            return false
        }
        request.cancel()
        sentRequest = nil
        return true
    }

    // MARK: -  Retryable

    @discardableResult
    func retry() -> Bool {
        guard let completion = completion else {
            return false
        }
        response(completion: completion)
        return true
    }
}

// MARK: -  MutableRequest

extension Request: MutableRequest {

    func appendHeader(_ header: RequestHeader) {
        let indexOrNil = headers.firstIndex { $0.key == header.key }
        if let index = indexOrNil {
            headers.remove(at: index)
        }
        headers.append(header)
    }
}

// MARK: -  CustomStringConvertible

extension Request: CustomStringConvertible {

    public var description: String {
        let pointerString = "\(Unmanaged.passUnretained(self).toOpaque())"
        return """
        <\(type(of: self)):\(pointerString)> to \
        `/\(endpoint.path)` \
        [\(endpoint.method.rawValue.uppercased())]
        """
    }
}
