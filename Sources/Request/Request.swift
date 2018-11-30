//
//  Created by Dmitry Frishbuter on 27/09/2018
//  Copyright © 2018 Ronas IT. All rights reserved.
//

import Alamofire

public final class Request: BaseRequest {

    private let request: DataRequest

    override init(endpoint: Endpoint,
                  sessionManager: SessionManager = .default) {
        request = sessionManager.request(endpoint.url,
                                         method: endpoint.method,
                                         parameters: endpoint.parameters,
                                         encoding: endpoint.parameterEncoding,
                                         headers: endpoint.headers.httpHeaders).validate()
        super.init(endpoint: endpoint, sessionManager: sessionManager)
    }

    public func cancel() {
        request.cancel()
    }

    func responseString(successHandler: @escaping SuccessHandler<String>,
                        failureHandler: @escaping FailureHandler) {
        request.responseString { response in
            switch response.result {
            case .failure(let error):
                self.handleError(error, forResponse: response, failureHandler: failureHandler)
            case .success(let string):
                self.handleResponseString(string, successHandler: successHandler, failureHandler: failureHandler)
            }
        }
    }

    func responseDecodableObject<Object: Decodable>(with decoder: JSONDecoder = JSONDecoder(),
                                                    successHandler: @escaping SuccessHandler<Object>,
                                                    failureHandler: @escaping FailureHandler) {
        request.responseData { response in
            switch response.result {
            case .failure(let error):
                self.handleError(error, forResponse: response, failureHandler: failureHandler)
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
        request.responseJSON(options: readingOptions) { response in
            switch response.result {
            case .failure(let error):
                self.handleError(error, forResponse: response, failureHandler: failureHandler)
            case .success(let json):
                self.handleResponseJSON(json, successHandler: successHandler, failureHandler: failureHandler)
            }
        }
    }

    func responseData(successHandler: @escaping SuccessHandler<Data>,
                      failureHandler: @escaping FailureHandler) {
        request.responseData { response in
            switch response.result {
            case .failure(let error):
                self.handleError(error, forResponse: response, failureHandler: failureHandler)
            case .success(let data):
                self.handleResponseData(data, successHandler: successHandler, failureHandler: failureHandler)
            }
        }
    }
}
