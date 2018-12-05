//
// Created by Nikita Zatsepilov on 30/11/2018.
// Copyright (c) 2018 Ronas IT. All rights reserved.
//

import Foundation
import Alamofire

final class GeneralRequest: Request, RequestErrorHandling {

    public let endpoint: Endpoint

    let authorization: RequestAuthorization
    let errorHandlers: [ErrorHandler]

    private let sessionManager: SessionManager
    private let httpHeadersFactory: HTTPHeadersFactory
    private var request: DataRequest?

    init(endpoint: Endpoint,
         authorization: RequestAuthorization = .none,
         sessionManager: SessionManager = .default,
         errorHandlers: [ErrorHandler] = [],
         httpHeadersFactory: HTTPHeadersFactory) {
        self.endpoint = endpoint
        self.authorization = authorization
        self.sessionManager = sessionManager
        self.errorHandlers = errorHandlers
        self.httpHeadersFactory = httpHeadersFactory
    }

    func responseString(success: @escaping Success<String>,
                        failure: @escaping Failure) {
        request = makeRequest().responseString { response in
            switch response.result {
            case .failure(let error):
                self.handleError(error, for: response, failure: failure)
            case .success(let string):
                success(string)
            }
        }
    }

    func responseDecodableObject<Object: Decodable>(with decoder: JSONDecoder = JSONDecoder(),
                                                    success: @escaping Success<Object>,
                                                    failure: @escaping Failure) {
        request = makeRequest().responseData { [weak self] response in
            switch response.result {
            case .failure(let error):
                self?.handleError(error, for: response, failure: failure)
            case .success(let data):
                do {
                    success(try decoder.decode(from: data))
                }
                catch {
                    self?.handleError(error, for: response, failure: failure)
                }
            }
        }
    }

    func responseJSON<Key: Hashable, Value: Any>(with readingOptions: JSONSerialization.ReadingOptions,
                                                 success: @escaping Success<[Key: Value]>,
                                                 failure: @escaping Failure) {
        request = makeRequest().responseJSON(options: readingOptions) { [weak self] response in
            switch response.result {
            case .failure(let error):
                self?.handleError(error, for: response, failure: failure)
            case .success(let json):
                guard let json = json as? [Key: Value] else {
                    // Standard error of `JSONSerialization`
                    failure(CocoaError.error(.keyValueValidation))
                    return
                }
                success(json)
            }
        }
    }

    func responseData(success: @escaping Success<Data>, failure: @escaping Failure) {
        request = makeRequest().responseData { [weak self] response in
            switch response.result {
            case .failure(let error):
                self?.handleError(error, for: response, failure: failure)
            case .success(let data):
                success(data)
            }
        }
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
