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
    private let errorHandlers: [ErrorHandler]
    private let errorResolvers: [ErrorResolver]

    public init(sessionManager: SessionManager = .default,
                requestAdapters: [RequestAdapter] = [],
                errorResolvers: [ErrorResolver] = [],
                errorHandlers: [ErrorHandler] = [GeneralErrorHandler()]) {
        self.sessionManager = sessionManager
        self.requestAdapters = requestAdapters
        self.errorHandlers = errorHandlers
        self.errorResolvers = errorResolvers
    }

    @discardableResult
    public func responseString(endpoint: Endpoint,
                               encoding: String.Encoding? = nil,
                               success: @escaping Success<String>,
                               failure: @escaping Failure) -> Request {
        let request = self.request(for: endpoint)
        request.responseString(encoding: encoding) { [weak self] response in
            self?.processResponse(of: request, response: response, success: success, failure: failure)
        }
        return request
    }

    @discardableResult
    public func responseData(endpoint: Endpoint,
                             success: @escaping Success<Data>,
                             failure: @escaping Failure) -> Request {
        let request = self.request(for: endpoint)
        request.responseData { [weak self] response in
            self?.processResponse(of: request, response: response, success: success, failure: failure)
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
            self?.processResponse(of: request, response: response, success: success, failure: failure)
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
            self?.processResponse(of: request, response: response, success: success, failure: failure)
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

    private func processResponse<T>(of request: NetworkRequest,
                                    response: DataResponse<T>,
                                    success: @escaping Success<T>,
                                    failure: @escaping Failure) {
        switch response.result {
        case .failure(let error):
            handleError(error, request: request, response: response, failure: failure)
        case .success(let result):
            success(result)
        }
    }

    private func handleError<T>(_ error: Error,
                                request: NetworkRequest,
                                response: DataResponse<T>,
                                failure: @escaping Failure) {
        guard var error = response.error else {
            return
        }

        if resolveError(error, request: request, failure: failure) {
            return
        }

        if handleError(&error, response: response, endpoint: request.endpoint) {
            return
        }

        failure(error)
    }

    private func resolveError(_ error: Error, request: NetworkRequest, failure: @escaping Failure) -> Bool {
        let errorResolverOrNil = errorResolvers.first { $0.canResolveError(error) }

        guard let errorResolver = errorResolverOrNil else {
            return false
        }

        errorResolver.resolveError(error, endpoint: request.endpoint) { resolution in
            switch resolution {
            case .retryRequest:
                request.retry()
            case .failure:
                failure(error)
            }
        }

        return true
    }

    private func handleError<T>(_ error: inout Error, response: DataResponse<T>, endpoint: Endpoint) -> Bool {
        for errorHandler in errorHandlers {
            if errorHandler.handle(error: &error, for: response, endpoint: endpoint) {
                return true
            }
        }
        return false
    }
}
