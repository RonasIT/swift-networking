//
//  Created by Dmitry Frishbuter on 27/09/2018
//  Copyright © 2018 Ronas IT. All rights reserved.
//

import Foundation
import Alamofire

public typealias Failure = (Error) -> Void

open class NetworkService {

    public typealias EncodingCompletionHandler = UploadRequest<GeneralResponse>.EncodingCompletionHandler

    private let sessionManager: Alamofire.SessionManager
    private let responseBuilder = GeneralResponseBuilder()
    var responseValidators: [ResponseValidator]?
    var errorHandlers: [ErrorHandler] = [GeneralErrorHandler()]

    public init(sessionManager: Alamofire.SessionManager = .default) {
        self.sessionManager = sessionManager
    }

    @discardableResult
    public func request(for endpoint: Endpoint,
                        success: @escaping () -> Void,
                        failure: @escaping Failure) -> Request<GeneralResponse> {
        let request = self.request(endpoint: endpoint)
        request.responseJSON { _, error in
            if let error = error {
                failure(error)
            }
            else {
                success()
            }
        }
        return request
    }

    @discardableResult
    public func uploadRequest(for endpoint: UploadEndpoint,
                              encodingCompletion: @escaping EncodingCompletionHandler,
                              success: @escaping () -> Void,
                              failure: @escaping Failure) -> UploadRequest<GeneralResponse> {
        let request = self.uploadRequest(endpoint: endpoint, encodingCompletion: encodingCompletion)
        request.responseJSON { _, error in
            if let error = error {
                failure(error)
            }
            else {
                success()
            }
        }
        return request
    }

    @discardableResult
    public func request<T: Decodable>(for endpoint: Endpoint,
                                      decoder: JSONDecoder = JSONDecoder(),
                                      success: @escaping (T) -> Void,
                                      failure: @escaping Failure) -> Request<GeneralResponse> {
        let request = self.request(endpoint: endpoint)
        request.responseJSON { response, error in
            if let error = error {
                failure(error)
            }
            else if let response = response {
                do {
                    let parsedResponse: T = try decoder.decode(from: response.jsonData)
                    success(parsedResponse)
                }
                catch {
                    failure(error)
                }
            }
        }
        return request
    }

    @discardableResult
    public func uploadRequest<T: Decodable>(for endpoint: UploadEndpoint,
                                            decoder: JSONDecoder = JSONDecoder(),
                                            encodingCompletion: @escaping EncodingCompletionHandler,
                                            success: @escaping (T) -> Void,
                                            failure: @escaping Failure) -> UploadRequest<GeneralResponse> {
        let request = self.uploadRequest(endpoint: endpoint, encodingCompletion: encodingCompletion)
        request.responseJSON { response, error in
            if let error = error {
                failure(error)
            }
            else if let response = response {
                do {
                    let parsedResponse: T = try decoder.decode(from: response.jsonData)
                    success(parsedResponse)
                }
                catch {
                    failure(error)
                }
            }
        }
        return request
    }

    // MARK: - Private

    private func request(endpoint: Endpoint) -> Request<GeneralResponse> {
        let request = Request(endpoint: endpointByAppendingAuthorizationInfo(to: endpoint), responseBuilder: responseBuilder)
        request.errorHandlers = errorHandlers
        if let responseValidators = responseValidators {
            request.responseValidators = responseValidators
        }
        return request
    }

    private func uploadRequest(endpoint: UploadEndpoint,
                               encodingCompletion: @escaping EncodingCompletionHandler) -> UploadRequest<GeneralResponse> {
        let request = UploadRequest(endpoint: endpointByAppendingAuthorizationInfo(to: endpoint),
                                    imageBodyParts: endpoint.imageBodyParts,
                                    responseBuilder: responseBuilder,
                                    encodingCompletion: encodingCompletion)
        request.errorHandlers = errorHandlers
        if let responseValidators = responseValidators {
            request.responseValidators = responseValidators
        }
        return request
    }

    private func endpointByAppendingAuthorizationInfo(to endpoint: Endpoint, token: String? = nil) -> Endpoint {
        return AuthorizedEndpoint.endpoint(source: endpoint, token: token)
    }

    // This original method implementation was commented because of impossibility to use current session implementation for requets auth
    //    private func endpointByAppendingAuthorizationInfo(to endpoint: Endpoint) -> Endpoint {
    //        guard let session = sessionService.session, let token = session.token else {
    //            return AuthorizedEndpoint.endpoint(source: endpoint, token: AppConfiguration.wildCardToken)
    //        }
    //        return AuthorizedEndpoint.endpoint(source: endpoint, token: token)
    //    }
}

// MARK: Endpoint

enum AuthorizedEndpoint: Endpoint {
    case endpoint(source: Endpoint, token: String?)
}

extension AuthorizedEndpoint {
    var method: HTTPMethod {
        switch self {
        case .endpoint(let endpoint, _):
            return endpoint.method
        }
    }

    var path: String {
        switch self {
        case .endpoint(let endpoint, _):
            return endpoint.path
        }
    }

    var parameters: Parameters? {
        switch self {
        case .endpoint(let endpoint, _):
            return endpoint.parameters
        }
    }

    var headers: [RequestHeader] {
        switch self {
        case .endpoint(let endpoint, let token):
            var headers = endpoint.headers
            if let token = token {
                headers.append(RequestHeaders.authorization(token))
            }
            return headers
        }
    }

    var baseURL: URL {
        switch self {
        case .endpoint(let endpoint, _):
            return endpoint.baseURL
        }
    }

    var parameterEncoding: ParameterEncoding {
        switch self {
        case .endpoint(let endpoint, _):
            return endpoint.parameterEncoding
        }
    }
}
