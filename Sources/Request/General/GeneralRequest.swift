//
// Created by Nikita Zatsepilov on 30/11/2018.
// Copyright (c) 2018 Ronas IT. All rights reserved.
//

import Foundation
import Alamofire

// FIXME: requires ARC check

final class GeneralRequest: NetworkRequest {

    public let endpoint: Endpoint

    let authorization: RequestAuthorization

    private let sessionManager: SessionManager
    private let httpHeadersFactory: HTTPHeadersFactory
    private var request: DataRequest?

    init(endpoint: Endpoint,
         authorization: RequestAuthorization = .none,
         sessionManager: SessionManager = .default,
         httpHeadersFactory: HTTPHeadersFactory) {
        self.endpoint = endpoint
        self.authorization = authorization
        self.sessionManager = sessionManager
        self.httpHeadersFactory = httpHeadersFactory
    }

    func responseObject<Object: Decodable>(queue: DispatchQueue? = nil,
                                           decoder: JSONDecoder,
                                           completion: @escaping Completion<DataResponse<Object>>) {
        makeRequest().responseObject(queue: queue, decoder: decoder, completionHandler: completion)
    }

    func responseString(queue: DispatchQueue? = nil,
                        encoding: String.Encoding? = nil,
                        completion: @escaping Completion<DataResponse<String>>) {
        makeRequest().responseString(queue: queue, encoding: encoding, completionHandler: completion)
    }

    func responseJSON(queue: DispatchQueue? = nil,
                      readingOptions: JSONSerialization.ReadingOptions,
                      completion: @escaping Completion<DataResponse<Any>>) {
        makeRequest().responseJSON(queue: queue, options: readingOptions, completionHandler: completion)
    }

    func responseData(queue: Dispatch.DispatchQueue? = nil,
                      completion: @escaping Completion<DataResponse<Data>>) {
        makeRequest().responseData(queue: queue, completionHandler: completion)
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
                                      headers: httpHeadersFactory.httpHeaders(for: self)).validate()
    }
}
