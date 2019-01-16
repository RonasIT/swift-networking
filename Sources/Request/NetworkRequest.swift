//
// Created by Nikita Zatsepilov on 30/11/2018.
// Copyright (c) 2018 Ronas IT. All rights reserved.
//

import Alamofire

final class NetworkRequest: Request {

    public let id: String
    public let endpoint: Endpoint

    private let sessionManager: SessionManager
    private var headers: [RequestHeader]

    private var sending: (() -> Void)?
    private var cancellation: (() -> Void)?

    init(sessionManager: SessionManager = .default, endpoint: Endpoint) {
        id = UUID().uuidString
        headers = endpoint.headers
        self.endpoint = endpoint
        self.sessionManager = sessionManager
    }

    deinit {
        print("\(self) \(#function)")
    }

    func response<Serializer: ResponseSerializer>(queue: DispatchQueue? = nil,
                                                  responseSerializer: Serializer,
                                                  completion: @escaping Completion<Serializer.SerializedObject>) {
        sending = { [unowned self] in
            let request = self.request()
            self.cancellation = request.cancel
            request.response(queue: queue, responseSerializer: responseSerializer, completionHandler: completion)
        }
        sending?()
    }

    func cancel() {
        cancellation?()
        cancellation = nil
        sending = nil
    }

    func retry() {
        sending?()
    }

    func append(_ header: RequestHeader) {
        let indexOrNil = headers.firstIndex { $0.key == header.key }
        if let index = indexOrNil {
            headers.remove(at: index)
        }
        headers.append(header)
    }

    // MARK: - Private

    private func request() -> DataRequest {
        return sessionManager.request(endpoint.url,
                                      method: endpoint.method,
                                      parameters: endpoint.parameters,
                                      encoding: endpoint.parameterEncoding,
                                      headers: headers.httpHeaders).validate()
    }
}
