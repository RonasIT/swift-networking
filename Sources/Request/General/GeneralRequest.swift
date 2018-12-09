//
// Created by Nikita Zatsepilov on 30/11/2018.
// Copyright (c) 2018 Ronas IT. All rights reserved.
//

import Alamofire

final class GeneralRequest: NetworkRequest, CancellableRequest {

    public let endpoint: Endpoint

    var headers: [RequestHeader] = []

    private let sessionManager: SessionManager
    private var request: DataRequest?

    init(sessionManager: SessionManager = .default,
         endpoint: Endpoint) {
        self.endpoint = endpoint
        self.headers = endpoint.headers
        self.sessionManager = sessionManager
    }

    func responseObject<Object: Decodable>(queue: DispatchQueue? = nil,
                                           decoder: JSONDecoder,
                                           completion: @escaping Completion<DataResponse<Object>>) {
        request = makeRequest()
        request?.responseObject(queue: queue, decoder: decoder, completionHandler: completion)
    }

    func responseString(queue: DispatchQueue? = nil,
                        encoding: String.Encoding? = nil,
                        completion: @escaping Completion<DataResponse<String>>) {
        request = makeRequest()
        request?.responseString(queue: queue, encoding: encoding, completionHandler: completion)
    }

    func responseJSON<Key: Hashable, Value>(queue: DispatchQueue? = nil,
                                            readingOptions: JSONSerialization.ReadingOptions,
                                            completion: @escaping Completion<DataResponse<[Key: Value]>>) {
        request = makeRequest()
        request?.responseJSON(queue: queue, readingOptions: readingOptions, completionHandler: completion)
    }

    func responseData(queue: Dispatch.DispatchQueue? = nil,
                      completion: @escaping Completion<DataResponse<Data>>) {
        request = makeRequest()
        request?.responseData(queue: queue, completionHandler: completion)
    }

    func cancel() {
        request?.cancel()
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
