//
//  Created by Dmitry Frishbuter on 27/09/2018
//  Copyright © 2018 Ronas IT. All rights reserved.
//

import Foundation
import Alamofire

open class NetworkService {

    public typealias SuccessHandler<T> = (T) -> Void
    public typealias FailureHandler = (Error) -> Void

    var errorHandlers: [ErrorHandler] = [GeneralErrorHandler()]

    private let sessionManager: SessionManager
    private let httpHeadersFactory: HTTPHeadersFactory

    public init(sessionManager: SessionManager = .default,
                httpHeadersFactory: HTTPHeadersFactory = GeneralHTTPHeadersFactory()) {
        self.sessionManager = sessionManager
        self.httpHeadersFactory = httpHeadersFactory
    }

    @discardableResult
    public func request<Object: Decodable>(for endpoint: Endpoint,
                                           decoder: JSONDecoder = JSONDecoder(),
                                           success: @escaping SuccessHandler<Object>,
                                           failure: @escaping FailureHandler) -> Request {
        let request = self.request(for: endpoint)
        request.responseDecodableObject(with: decoder, success: success, failure: failure)
        return request
    }

    @discardableResult
    public func request(for endpoint: Endpoint,
                        success: @escaping SuccessHandler<String>,
                        failure: @escaping FailureHandler) -> Request {
        let request = self.request(for: endpoint)
        request.responseString(success: success, failure: failure)
        return request
    }

    @discardableResult
    public func request(for endpoint: Endpoint,
                        success: @escaping SuccessHandler<Data>,
                        failure: @escaping FailureHandler) -> Request {
        let request = self.request(for: endpoint)
        request.responseData(success: success, failure: failure)
        return request
    }

    @discardableResult
    public func request(for endpoint: Endpoint,
                        readingOptions: JSONSerialization.ReadingOptions = .allowFragments,
                        success: @escaping SuccessHandler<Any>,
                        failure: @escaping FailureHandler) -> Request {
        let request = self.request(for: endpoint)
        request.responseJSON(with: readingOptions, success: success, failure: failure)
        return request
    }

    @discardableResult
    public func uploadRequest<Object: Decodable>(for endpoint: UploadEndpoint,
                                                 decoder: JSONDecoder = JSONDecoder(),
                                                 success: @escaping SuccessHandler<Object>,
                                                 failure: @escaping FailureHandler) -> Request {
        let request = self.uploadRequest(for: endpoint)
        request.responseDecodableObject(with: decoder, success: success, failure: failure)
        return request
    }

    @discardableResult
    public func uploadRequest(for endpoint: UploadEndpoint,
                              success: @escaping SuccessHandler<String>,
                              failure: @escaping FailureHandler) -> Request {
        let request = self.uploadRequest(for: endpoint)
        request.responseString(success: success, failure: failure)
        return request
    }

    @discardableResult
    public func uploadRequest(for endpoint: UploadEndpoint,
                              success: @escaping SuccessHandler<Data>,
                              failure: @escaping FailureHandler) -> Request {
        let request = self.uploadRequest(for: endpoint)
        request.responseData(success: success, failure: failure)
        return request
    }

    @discardableResult
    public func uploadRequest(for endpoint: UploadEndpoint,
                              readingOptions: JSONSerialization.ReadingOptions = .allowFragments,
                              success: @escaping SuccessHandler<Any>,
                              failure: @escaping FailureHandler) -> Request {
        let request = self.uploadRequest(for: endpoint)
        request.responseJSON(with: readingOptions, success: success, failure: failure)
        return request
    }

    public func authorization(for endpoint: Endpoint) -> RequestAuthorization {
        return .none
    }

    // MARK: - Private

    private func request(for endpoint: Endpoint) -> Request {
        let request = GeneralRequest(endpoint: endpoint,
                                     authorization: authorization(for: endpoint),
                                     sessionManager: sessionManager,
                                     httpHeadersFactory: httpHeadersFactory)
        request.errorHandlers = errorHandlers
        return request
    }

    private func uploadRequest(for endpoint: UploadEndpoint) -> Request {
        let request = GeneralUploadRequest(endpoint: endpoint,
                                           authorization: authorization(for: endpoint),
                                           sessionManager: sessionManager,
                                           httpHeadersFactory: httpHeadersFactory,
                                           imageBodyParts: endpoint.imageBodyParts)
        request.errorHandlers = errorHandlers
        return request
    }
}
