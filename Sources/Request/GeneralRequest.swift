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

    func responseString(successHandler: @escaping SuccessHandler<String>,
                        failureHandler: @escaping FailureHandler) {
        request = makeRequest().responseString { response in
            switch response.result {
            case .failure(let error):
                self.handleError(error, for: response, failureHandler: failureHandler)
            case .success(let string):
                self.handleResponseString(string, successHandler: successHandler, failureHandler: failureHandler)
            }
        }
    }

    func responseDecodableObject<Object: Decodable>(with decoder: JSONDecoder = JSONDecoder(),
                                                    successHandler: @escaping SuccessHandler<Object>,
                                                    failureHandler: @escaping FailureHandler) {
        request = makeRequest().responseData { response in
            switch response.result {
            case .failure(let error):
                self.handleError(error, for: response, failureHandler: failureHandler)
            case .success(let data):
                self.handleResponseDecodableObject(with: data,
                                                   decoder: decoder,
                                                   successHandler: successHandler,
                                                   failureHandler: failureHandler)
            }
        }
    }

    func responseJSON(with readingOptions: JSONSerialization.ReadingOptions = .allowFragments,
                      successHandler: @escaping SuccessHandler<Any>,
                      failureHandler: @escaping FailureHandler) {
        request = makeRequest().responseJSON(options: readingOptions) { response in
            switch response.result {
            case .failure(let error):
                self.handleError(error, for: response, failureHandler: failureHandler)
            case .success(let json):
                self.handleResponseJSON(json, successHandler: successHandler, failureHandler: failureHandler)
            }
        }
    }

    func responseData(successHandler: @escaping SuccessHandler<Data>,
                      failureHandler: @escaping FailureHandler) {
        request = makeRequest().responseData { response in
            switch response.result {
            case .failure(let error):
                self.handleError(error, for: response, failureHandler: failureHandler)
            case .success(let data):
                self.handleResponseData(data, successHandler: successHandler, failureHandler: failureHandler)
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
