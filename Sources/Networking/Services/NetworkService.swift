//
//  Created by Dmitry Frishbuter on 27/09/2018
//  Copyright © 2018 Ronas IT. All rights reserved.
//

import Foundation
import Alamofire

public typealias Success<T> = (T) -> Void
public typealias Failure = (Error) -> Void

open class NetworkService {

    public typealias JSONReadingOptions = JSONSerialization.ReadingOptions

    public var errorHandlers: [ErrorHandler] = [GeneralErrorHandler()]

    private let sessionManager: SessionManager
    private let requestAuthorizationService: RequestAuthorizationService
    private let httpHeadersFactory: HTTPHeadersFactory

    public init(sessionManager: SessionManager = .default,
                requestAuthorizationService: RequestAuthorizationService = GeneralRequestAuthorizationService(),
                httpHeadersFactory: HTTPHeadersFactory = GeneralHTTPHeadersFactory()) {
        self.sessionManager = sessionManager
        self.requestAuthorizationService = requestAuthorizationService
        self.httpHeadersFactory = httpHeadersFactory
    }

    @discardableResult
    public func request<Object: Decodable>(for endpoint: Endpoint,
                                           decoder: JSONDecoder = JSONDecoder(),
                                           success: @escaping Success<Object>,
                                           failure: @escaping Failure) -> Request {
        let request = self.request(for: endpoint)
        request.responseDecodableObject(with: decoder, success: success, failure: failure)
        return request
    }

    @discardableResult
    public func request(for endpoint: Endpoint,
                        success: @escaping Success<String>,
                        failure: @escaping Failure) -> Request {
        let request = self.request(for: endpoint)
        request.responseString(success: success, failure: failure)
        return request
    }

    @discardableResult
    public func request(for endpoint: Endpoint,
                        success: @escaping Success<Data>,
                        failure: @escaping Failure) -> Request {
        let request = self.request(for: endpoint)
        request.responseData(success: success, failure: failure)
        return request
    }

    @discardableResult
    public func request<Key: Hashable, Value: Any>(for endpoint: Endpoint,
                                                   readingOptions: JSONReadingOptions = .allowFragments,
                                                   success: @escaping Success<[Key: Value]>,
                                                   failure: @escaping Failure) -> Request {
        let request = self.request(for: endpoint)
        request.responseJSON(with: readingOptions, success: success, failure: failure)
        return request
    }

    @discardableResult
    public func uploadRequest<Object: Decodable>(for endpoint: UploadEndpoint,
                                                 decoder: JSONDecoder = JSONDecoder(),
                                                 success: @escaping Success<Object>,
                                                 failure: @escaping Failure) -> Request {
        let request = self.uploadRequest(for: endpoint)
        request.responseDecodableObject(with: decoder, success: success, failure: failure)
        return request
    }

    @discardableResult
    public func uploadRequest(for endpoint: UploadEndpoint,
                              success: @escaping Success<String>,
                              failure: @escaping Failure) -> Request {
        let request = self.uploadRequest(for: endpoint)
        request.responseString(success: success, failure: failure)
        return request
    }

    @discardableResult
    public func uploadRequest(for endpoint: UploadEndpoint,
                              success: @escaping Success<Data>,
                              failure: @escaping Failure) -> Request {
        let request = self.uploadRequest(for: endpoint)
        request.responseData(success: success, failure: failure)
        return request
    }

    @discardableResult
    public func uploadRequest<Key: Hashable, Value: Any>(for endpoint: UploadEndpoint,
                                                         readingOptions: JSONReadingOptions = .allowFragments,
                                                         success: @escaping Success<[Key: Value]>,
                                                         failure: @escaping Failure) -> Request {
        let request = self.uploadRequest(for: endpoint)
        request.responseJSON(with: readingOptions, success: success, failure: failure)
        return request
    }

    // MARK: - Private

    private func request(for endpoint: Endpoint) -> Request {
        return GeneralRequest(endpoint: endpoint,
                              authorization: requestAuthorizationService.authorization(for: endpoint),
                              sessionManager: sessionManager,
                              errorHandlers: errorHandlers,
                              httpHeadersFactory: httpHeadersFactory)
    }

    private func uploadRequest(for endpoint: UploadEndpoint) -> Request {
        return GeneralUploadRequest(endpoint: endpoint,
                                    authorization: requestAuthorizationService.authorization(for: endpoint),
                                    sessionManager: sessionManager,
                                    errorHandlers: errorHandlers,
                                    httpHeadersFactory: httpHeadersFactory)
    }
}
