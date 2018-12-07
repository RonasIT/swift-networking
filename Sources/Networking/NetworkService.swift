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

    private let sessionManager: SessionManager

    private let requestAdapters: [RequestAdapter]
    private let responseInterceptors: [ResponseInterceptor]

    public init(sessionManager: SessionManager = .default,
                requestAdapters: [RequestAdapter] = [],
                responseInterceptors: [ResponseInterceptor] = [ErrorResponseInterceptor()]) {
        self.sessionManager = sessionManager
        self.requestAdapters = requestAdapters
        self.responseInterceptors = responseInterceptors
    }

    @discardableResult
    public func responseString(endpoint: Endpoint,
                               encoding: String.Encoding? = nil,
                               success: @escaping Success<String>,
                               failure: @escaping Failure) -> Request {
        let request = self.request(for: endpoint)
        request.responseString(encoding: encoding) { [weak self] response in
            self?.processResponse(response, endpoint: endpoint, success: success, failure: failure)
        }
        return request
    }

    @discardableResult
    public func responseData(endpoint: Endpoint,
                             success: @escaping Success<Data>,
                             failure: @escaping Failure) -> Request {
        let request = self.request(for: endpoint)
        request.responseData { [weak self] response in
            self?.processResponse(response, endpoint: endpoint, success: success, failure: failure)
        }
        return request
    }

    @discardableResult
    public func responseObject<Object>(endpoint: Endpoint,
                                       decoder: JSONDecoder = JSONDecoder(),
                                       success: @escaping Success<Object>,
                                       failure: @escaping Failure) -> Request where Object: Decodable {
        let request = self.request(for: endpoint)
        request.responseObject(decoder: decoder) { [weak self] (response: DataResponse<Object>) in
            self?.processResponse(response, endpoint: endpoint, success: success, failure: failure)
        }
        return request
    }

    @discardableResult
    public func responseJSON<Key, Value>(endpoint: Endpoint,
                                         readingOptions: JSONReadingOptions = .allowFragments,
                                         success: @escaping Success<[Key: Value]>,
                                         failure: @escaping Failure) -> Request where Key: Hashable, Value: Any {
        let request = self.request(for: endpoint)
        request.responseJSON(readingOptions: readingOptions) { [weak self] response in
            self?.processResponse(response, endpoint: endpoint, success: success, failure: failure)
        }
        return request
    }

    // MARK: - Private

    private func request(for endpoint: Endpoint) -> GeneralRequest {
        let request = GeneralRequest(sessionManager: sessionManager, endpoint: endpoint)
        adaptRequest(request)
        return request
    }

    private func uploadRequest(for endpoint: UploadEndpoint) -> GeneralUploadRequest {
        let request = GeneralUploadRequest(sessionManager: sessionManager, endpoint: endpoint)
        adaptRequest(request)
        return request
    }

    private func adaptRequest(_ request: NetworkRequest) {
        requestAdapters.forEach { $0.adaptRequest(request) }
    }

    private func processResponse<T>(_ response: DataResponse<T>,
                                    endpoint: Endpoint,
                                    success: @escaping Success<T>,
                                    failure: @escaping Failure) {
        let responseCallback = ResponseCallback(success: success, failure: failure)
        for interceptor in responseInterceptors {
            if interceptor.interceptResponse(response, endpoint: endpoint, responseCallback: responseCallback) {
                return
            }
        }

        switch response.result {
        case .failure(let error):
            failure(error)
        case .success(let result):
            success(result)
        }
    }
}
