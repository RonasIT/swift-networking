//
//  Created by Dmitry Frishbuter on 27/09/2018
//  Copyright © 2018 Ronas IT. All rights reserved.
//

import Alamofire

public typealias Success<T> = (T) -> Void
public typealias Failure = (Error) -> Void

open class NetworkService {

    private let sessionManager: SessionManager

    private let requestAdapters: [RequestAdapter]
    private let errorHandlers: [ErrorHandler]

    public init(sessionManager: SessionManager = .default,
                requestAdapters: [RequestAdapter] = [],
                errorHandlers: [ErrorHandler] = [GeneralErrorHandler()]) {
        self.sessionManager = sessionManager
        self.requestAdapters = requestAdapters
        self.errorHandlers = errorHandlers
    }

    @discardableResult
    public func request(endpoint: Endpoint,
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
    public func request(endpoint: Endpoint,
                        success: @escaping Success<Data>,
                        failure: @escaping Failure) -> Request {
        let request = self.request(for: endpoint)
        request.responseData { [weak self] response in
            self?.processResponse(response, endpoint: endpoint, success: success, failure: failure)
        }
        return request
    }

    @discardableResult
    public func request<Object>(endpoint: Endpoint,
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
    public func request<Key, Value>(endpoint: Endpoint,
                                    readingOptions: JSONSerialization.ReadingOptions = .allowFragments,
                                    success: @escaping Success<[Key: Value]>,
                                    failure: @escaping Failure) -> Request where Key: Hashable, Value: Any {
        let request = self.request(for: endpoint)
        request.responseJSON(readingOptions: readingOptions) { [weak self] response in
            self?.processResponse(response, endpoint: endpoint, success: success, failure: failure)
        }
        return request
    }

    @discardableResult
    public func uploadRequest(endpoint: UploadEndpoint,
                              encoding: String.Encoding? = nil,
                              success: @escaping Success<String>,
                              failure: @escaping Failure) -> Request {
        let request = self.uploadRequest(for: endpoint)
        request.responseString(encoding: encoding) { [weak self] response in
            self?.processResponse(response, endpoint: endpoint, success: success, failure: failure)
        }
        return request
    }

    @discardableResult
    public func uploadRequest(endpoint: UploadEndpoint,
                              success: @escaping Success<Data>,
                              failure: @escaping Failure) -> Request {
        let request = self.uploadRequest(for: endpoint)
        request.responseData { [weak self] response in
            self?.processResponse(response, endpoint: endpoint, success: success, failure: failure)
        }
        return request
    }

    @discardableResult
    public func uploadRequest<Object>(endpoint: UploadEndpoint,
                                      decoder: JSONDecoder = JSONDecoder(),
                                      success: @escaping Success<Object>,
                                      failure: @escaping Failure) -> Request where Object: Decodable {
        let request = self.uploadRequest(for: endpoint)
        request.responseObject(decoder: decoder) { [weak self] (response: DataResponse<Object>) in
            self?.processResponse(response, endpoint: endpoint, success: success, failure: failure)
        }
        return request
    }

    @discardableResult
    public func uploadRequest<Key, Value>(endpoint: UploadEndpoint,
                                          readingOptions: JSONSerialization.ReadingOptions = .allowFragments,
                                          success: @escaping Success<[Key: Value]>,
                                          failure: @escaping Failure) -> Request where Key: Hashable, Value: Any {
        let request = self.uploadRequest(for: endpoint)
        request.responseJSON(readingOptions: readingOptions) { [weak self] response in
            self?.processResponse(response, endpoint: endpoint, success: success, failure: failure)
        }
        return request
    }

    // MARK: - Private

    private func request(for endpoint: Endpoint) -> GeneralRequest {
        let request = GeneralRequest(sessionManager: sessionManager, endpoint: endpoint)
        adapt(request)
        return request
    }

    private func uploadRequest(for endpoint: UploadEndpoint) -> GeneralUploadRequest {
        let request = GeneralUploadRequest(sessionManager: sessionManager, endpoint: endpoint)
        adapt(request)
        return request
    }

    private func adapt(_ request: NetworkRequest) {
        requestAdapters.forEach { $0.adapt(request) }
    }

    private func processResponse<T>(_ response: DataResponse<T>,
                                    endpoint: Endpoint,
                                    success: @escaping Success<T>,
                                    failure: @escaping Failure) {
        switch response.result {
        case .failure(let error):
            handleError(error, response: response, endpoint: endpoint, failure: failure)
        case .success(let result):
            success(result)
        }
    }

    private func handleError<T>(_ error: Error, response: DataResponse<T>, endpoint: Endpoint, failure: @escaping Failure) {
        var error = error
        for errorHandler in errorHandlers {
            if errorHandler.handle(error: &error, for: response, endpoint: endpoint) {
                return
            }
        }

        failure(error)
    }
}
