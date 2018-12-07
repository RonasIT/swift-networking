//
// Created by Nikita Zatsepilov on 30/11/2018.
// Copyright (c) 2018 Ronas IT. All rights reserved.
//

import Foundation
import Alamofire

// FIXME: requires ARC check

final class GeneralRequest: NetworkRequest {

    public let endpoint: Endpoint

    private(set) var additionalHeaders: [RequestHeader] = []

    private let sessionManager: SessionManager
    private var request: DataRequest?

    private var responseHandler: (() -> Void)?

    init(sessionManager: SessionManager = .default,
         endpoint: Endpoint) {
        self.endpoint = endpoint
        self.sessionManager = sessionManager
    }

    func responseObject<Object: Decodable>(queue: DispatchQueue? = nil,
                                           decoder: JSONDecoder,
                                           completion: @escaping Completion<DataResponse<Object>>) {
        responseHandler = { [weak self] in
            self?.makeRequest().responseObject(queue: queue, decoder: decoder, completionHandler: completion)
        }
        responseHandler?()
    }

    func responseString(queue: DispatchQueue? = nil,
                        encoding: String.Encoding? = nil,
                        completion: @escaping Completion<DataResponse<String>>) {
        responseHandler = { [weak self] in
            self?.makeRequest().responseString(queue: queue, encoding: encoding, completionHandler: completion)
        }
        responseHandler?()
    }

    func responseJSON<Key: Hashable, Value>(queue: DispatchQueue? = nil,
                                            readingOptions: JSONSerialization.ReadingOptions,
                                            completion: @escaping Completion<DataResponse<[Key: Value]>>) {
        responseHandler = { [weak self] in
            self?.makeRequest().responseJSON(queue: queue,
                                             readingOptions: readingOptions,
                                             completionHandler: completion)
        }
        responseHandler?()
    }

    func responseData(queue: Dispatch.DispatchQueue? = nil,
                      completion: @escaping Completion<DataResponse<Data>>) {
        responseHandler = { [weak self] in
            self?.makeRequest().responseData(queue: queue, completionHandler: completion)
        }
        responseHandler?()
    }

    func cancel() {
        request?.cancel()
    }

    func retry() {
        responseHandler?()
    }

    func addHeader(_ header: RequestHeader) {
        // TODO: find way to move to `NetworkRequest` protocol
        let headerIndexOrNil = additionalHeaders.firstIndex { existingHeader in
            return existingHeader.key == header.key
        }

        if let headerIndex = headerIndexOrNil {
            additionalHeaders.remove(at: headerIndex)
        }

        additionalHeaders.append(header)
    }

    // MARK: Private

    private func makeRequest() -> DataRequest {
        return sessionManager.request(endpoint.url,
                                      method: endpoint.method,
                                      parameters: endpoint.parameters,
                                      encoding: endpoint.parameterEncoding,
                                      headers: httpHeaders).validate()
    }
}
