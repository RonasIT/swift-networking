//
// Created by Nikita Zatsepilov on 30/11/2018.
// Copyright (c) 2018 Ronas IT. All rights reserved.
//

import Foundation
import Alamofire

final class GeneralDataRequest: Request, RequestErrorHandling, RequestResponseHandling {

    public let endpoint: Endpoint
    public var auth: RequestAuth = .none
    public var errorHandlers: [ErrorHandler] = []

    private let sessionManager: SessionManager
    private let httpHeadersFactory: HTTPHeadersFactory

    private var request: DataRequest?

    init(endpoint: Endpoint, sessionManager: SessionManager = .default, httpHeadersFactory: HTTPHeadersFactory) {
        self.endpoint = endpoint
        self.sessionManager = sessionManager
        self.httpHeadersFactory = httpHeadersFactory
    }

    func responseString(success: @escaping SuccessHandler<String>,
                        failure: @escaping FailureHandler) {
        request = makeRequest().responseString { response in
            switch response.result {
            case .failure(let error):
                self.handleError(error, for: response, failure: failure)
            case .success(let string):
                self.handleResponseString(string, success: success, failure: failure)
            }
        }
    }

    func responseDecodableObject<Object: Decodable>(with decoder: JSONDecoder = JSONDecoder(),
                                                    success: @escaping SuccessHandler<Object>,
                                                    failure: @escaping FailureHandler) {
        request = makeRequest().responseData { response in
            switch response.result {
            case .failure(let error):
                self.handleError(error, for: response, failure: failure)
            case .success(let data):
                self.handleResponseDecodableObject(with: data,
                                                   decoder: decoder,
                                                   success: success,
                                                   failure: failure)
            }
        }
    }

    func responseJSON(with readingOptions: JSONSerialization.ReadingOptions = .allowFragments,
                      success: @escaping SuccessHandler<Any>,
                      failure: @escaping FailureHandler) {
        request = makeRequest().responseJSON(options: readingOptions) { response in
            switch response.result {
            case .failure(let error):
                self.handleError(error, for: response, failure: failure)
            case .success(let json):
                self.handleResponseJSON(json, success: success, failure: failure)
            }
        }
    }

    func responseData(success: @escaping SuccessHandler<Data>,
                      failure: @escaping FailureHandler) {
        request = makeRequest().responseData { response in
            switch response.result {
            case .failure(let error):
                self.handleError(error, for: response, failure: failure)
            case .success(let data):
                self.handleResponseData(data, success: success, failure: failure)
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
