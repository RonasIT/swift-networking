//
// Created by Nikita Zatsepilov on 30/11/2018.
// Copyright (c) 2018 Ronas IT. All rights reserved.
//

import Alamofire

final class GeneralRequest: NetworkRequest, CancellableRequest {

    public let endpoint: Endpoint

    let identifier: String = UUID().uuidString
    var headers: [RequestHeader] = []

    private let sessionManager: SessionManager
    private var request: DataRequest?

    private var sending: (() -> Void)?

    init(sessionManager: SessionManager = .default,
         endpoint: Endpoint) {
        self.endpoint = endpoint
        self.headers = endpoint.headers
        self.sessionManager = sessionManager
    }

    func responseObject<Object: Decodable>(queue: DispatchQueue? = nil,
                                           decoder: JSONDecoder,
                                           completion: @escaping Completion<DataResponse<Object>>) {
        let request = makeRequest()
        self.request = request
        sending = {
            request.responseObject(queue: queue, decoder: decoder, completionHandler: completion)
        }
        sending?()
    }

    func responseString(queue: DispatchQueue? = nil,
                        encoding: String.Encoding? = nil,
                        completion: @escaping Completion<DataResponse<String>>) {
        let request = makeRequest()
        self.request = request
        sending = {
            request.responseString(queue: queue, encoding: encoding, completionHandler: completion)
        }
        sending?()
    }

    func responseJSON<Key: Hashable, Value>(queue: DispatchQueue? = nil,
                                            readingOptions: JSONSerialization.ReadingOptions,
                                            completion: @escaping Completion<DataResponse<[Key: Value]>>) {
        let request = makeRequest()
        self.request = request
        sending = {
            request.responseJSON(queue: queue, readingOptions: readingOptions, completionHandler: completion)
        }
        sending?()
    }

    func responseData(queue: Dispatch.DispatchQueue? = nil, completion: @escaping Completion<DataResponse<Data>>) {
        let request = makeRequest()
        self.request = request
        sending = {
            request.responseData(queue: queue, completionHandler: completion)
        }
        sending?()
    }

    func cancel() {
        request?.cancel()
        request = nil
        sending = nil
    }

    func retry() {
        sending?()
    }

    // MARK: Private

    private func makeRequest() -> DataRequest {
        return sessionManager.request(endpoint.url,
                                      method: endpoint.method,
                                      parameters: endpoint.parameters,
                                      encoding: endpoint.parameterEncoding,
                                      headers: headers.httpHeaders).validate()
    }
}
