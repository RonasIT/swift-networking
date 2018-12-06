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
    private let requestAuthorizationService: RequestAuthorizationService
    private let requestErrorHandlingService: RequestErrorHandlingService
    private let httpHeadersFactory: HTTPHeadersFactory

    public init(sessionManager: SessionManager = .default,
                requestAuthorizationService: RequestAuthorizationService = GeneralRequestAuthorizationService(),
                requestErrorHandlingService: RequestErrorHandlingService = GeneralRequestErrorHandlingService(),
                httpHeadersFactory: HTTPHeadersFactory = GeneralHTTPHeadersFactory()) {
        self.sessionManager = sessionManager
        self.requestAuthorizationService = requestAuthorizationService
        self.requestErrorHandlingService = requestErrorHandlingService
        self.httpHeadersFactory = httpHeadersFactory
    }

    @discardableResult
    public func requestString(endpoint: Endpoint,
                              encoding: String.Encoding? = nil,
                              success: @escaping Success<String>,
                              failure: @escaping Failure) -> Request {
        let request = self.request(for: endpoint)
        request.responseString(encoding: encoding) { [weak self] response in
            self?.processResponse(response, success: success, failure: failure)
        }
        return request
    }

    @discardableResult
    public func requestData(endpoint: Endpoint,
                            success: @escaping Success<Data>,
                            failure: @escaping Failure) -> Request {
        let request = self.request(for: endpoint)
        request.responseData { [weak self] response in
            self?.processResponse(response, success: success, failure: failure)
        }
        return request
    }

    @discardableResult
    public func requestObject<Object>(endpoint: Endpoint,
                                      decoder: JSONDecoder = JSONDecoder(),
                                      success: @escaping Success<Object>,
                                      failure: @escaping Failure) -> Request where Object: Decodable {
        let request = self.request(for: endpoint)
        request.responseObject(decoder: decoder) { [weak self] (response: DataResponse<Object>) in
            self?.processResponse(response, success: success, failure: failure)
        }
        return request
    }

    @discardableResult
    public func requestJSON<Key, Value>(endpoint: Endpoint,
                                        readingOptions: JSONReadingOptions = .allowFragments,
                                        success: @escaping Success<[Key: Value]>,
                                        failure: @escaping Failure) -> Request where Key: Hashable, Value: Any {
        let request = self.request(for: endpoint)
        request.responseJSON(readingOptions: readingOptions) { [weak self] response in
            self?.processJSONResponse(response, success: success, failure: failure)
        }
        return request
    }

    // MARK: - Private

    private func request(for endpoint: Endpoint) -> GeneralRequest {
        return GeneralRequest(endpoint: endpoint,
                              authorization: requestAuthorizationService.requestAuthorization(for: endpoint),
                              sessionManager: sessionManager,
                              httpHeadersFactory: httpHeadersFactory)
    }

    private func uploadRequest(for endpoint: UploadEndpoint) -> GeneralUploadRequest {
        return GeneralUploadRequest(endpoint: endpoint,
                                    authorization: requestAuthorizationService.requestAuthorization(for: endpoint),
                                    sessionManager: sessionManager,
                                    httpHeadersFactory: httpHeadersFactory)
    }

    private func processResponse<T>(_ response: DataResponse<T>,
                                    success: @escaping Success<T>,
                                    failure: @escaping Failure) {
        switch response.result {
        case .failure(let error):
            failure(error)
        case .success(let result):
            success(result)
        }
    }

    private func processJSONResponse<Key, Value>(_ response: DataResponse<Any>,
                                                 success: @escaping Success<[Key: Value]>,
                                                 failure: @escaping Failure) where Key: Hashable, Value: Any {
        // TODO: use custom response serializer
        switch response.result {
        case .failure(let error):
            failure(error)
        case .success(let result):
            if let json = result as? [Key: Value] {
                success(json)
            } else {
                failure(CocoaError.error(.keyValueValidation))
            }
        }
    }
}
