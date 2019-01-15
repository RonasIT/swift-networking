//
//  Created by Dmitry Frishbuter on 27/09/2018
//  Copyright © 2018 Ronas IT. All rights reserved.
//

import Alamofire

public typealias Success<T> = (T) -> Void
public typealias Failure = (Error) -> Void

open class NetworkService {

    private let sessionManager: SessionManager
    private let requestAdaptingService: RequestAdaptingServiceProtocol?
    private let responseHandlingService: ResponseHandlingServiceProtocol?

    public init(sessionManager: SessionManager = .default,
                requestAdaptingService: RequestAdaptingServiceProtocol? = nil,
                responseHandlingService: ResponseHandlingServiceProtocol? = nil) {
        self.sessionManager = sessionManager
        self.requestAdaptingService = requestAdaptingService
        self.responseHandlingService = responseHandlingService
    }

    @discardableResult
    public func request(endpoint: Endpoint,
                        encoding: String.Encoding? = nil,
                        success: @escaping Success<String>,
                        failure: @escaping Failure) -> CancellableRequest {
        fatalError()
//        let request = self.request(for: endpoint)
//        let requestId = request.id
//        request.responseString(encoding: encoding) { [weak self] response in
//            self?.completeRequest(response, requestId: requestId, success: success, failure: failure)
//        }
//        return request
    }

    @discardableResult
    public func request(endpoint: Endpoint,
                        success: @escaping Success<Data>,
                        failure: @escaping Failure) -> CancellableRequest {
        fatalError()
//        let request = self.request(for: endpoint)
//        let unmanagedRequest = Unmanaged.passUnretained(request)
//        request.responseData { [weak self] response in
//            let request = unmanagedRequest.takeRetainedValue()
//            self?.completeRequest(request, response: response, success: success, failure: failure)
//            unmanagedRequest.release()
//        }
//        return request
    }

    @discardableResult
    public func request<Object>(endpoint: Endpoint,
                                decoder: JSONDecoder = JSONDecoder(),
                                success: @escaping Success<Object>,
                                failure: @escaping Failure) -> CancellableRequest where Object: Decodable {
        let request = self.request(for: endpoint)
        let unmanagedRequest = Unmanaged.passRetained(request)
        request.responseObject(decoder: decoder) { [weak self] (response: DataResponse<Object>) in
            let request = unmanagedRequest.takeRetainedValue()
            self?.completeRequest(request, response: response, success: success, failure: failure)
            unmanagedRequest.release()
        }
        return request
    }

    @discardableResult
    public func request<Key, Value>(endpoint: Endpoint,
                                    readingOptions: JSONSerialization.ReadingOptions = .allowFragments,
                                    success: @escaping Success<[Key: Value]>,
                                    failure: @escaping Failure) -> CancellableRequest where Key: Hashable, Value: Any {
        fatalError()
//        let request = self.request(for: endpoint)
//        let requestId = request.id
//        request.responseJSON(readingOptions: readingOptions) { [weak self] response in
//            //self?.completeRequest(response, requestId: requestId, success: success, failure: failure)
//        }
//        return request
    }

    @discardableResult
    public func uploadRequest(endpoint: UploadEndpoint,
                              encoding: String.Encoding? = nil,
                              success: @escaping Success<String>,
                              failure: @escaping Failure) -> CancellableRequest {
        fatalError()
//        let request = self.uploadRequest(for: endpoint)
//        let requestId = request.id
//        request.responseString(encoding: encoding) { [weak self] response in
//            //self?.completeRequest(response, requestId: requestId, success: success, failure: failure)
//        }
//        return request
    }

    @discardableResult
    public func uploadRequest(endpoint: UploadEndpoint,
                              success: @escaping Success<Data>,
                              failure: @escaping Failure) -> CancellableRequest {
        fatalError()
//        let request = self.uploadRequest(for: endpoint)
//        let requestId = request.id
//        request.responseData { [weak self] response in
//            self?.completeRequest(response, requestId: requestId, success: success, failure: failure)
//        }
//        return request
    }

    @discardableResult
    public func uploadRequest<Object>(endpoint: UploadEndpoint,
                                      decoder: JSONDecoder = JSONDecoder(),
                                      success: @escaping Success<Object>,
                                      failure: @escaping Failure) -> CancellableRequest where Object: Decodable {
        fatalError()
//        let request = self.uploadRequest(for: endpoint)
//        let requestId = request.id
//        request.responseObject(decoder: decoder) { [weak self] (response: DataResponse<Object>) in
//            self?.completeRequest(response, requestId: requestId, success: success, failure: failure)
//        }
//        return request
    }

    @discardableResult
    public func uploadRequest<Key, Value>(endpoint: UploadEndpoint,
                                          readingOptions: JSONSerialization.ReadingOptions = .allowFragments,
                                          success: @escaping Success<[Key: Value]>,
                                          failure: @escaping Failure) -> CancellableRequest where Key: Hashable, Value: Any {
        fatalError()
//        let request = self.uploadRequest(for: endpoint)
//        let requestId = request.id
//        request.responseJSON(readingOptions: readingOptions) { [weak self] response in
//            self?.completeRequest(response, requestId: requestId, success: success, failure: failure)
//        }
//        return request
    }

    // MARK: - Private

    private func request(for endpoint: Endpoint) -> GeneralRequest {
        let request = GeneralRequest(sessionManager: sessionManager, endpoint: endpoint)
        if let requestAdaptingService = requestAdaptingService {
            requestAdaptingService.adapt(request)
        }
        return request
    }

    private func uploadRequest(for endpoint: UploadEndpoint) -> GeneralUploadRequest {
        let request = GeneralUploadRequest(sessionManager: sessionManager, endpoint: endpoint)
        if let requestAdaptingService = requestAdaptingService {
            requestAdaptingService.adapt(request)
        }
        return request
    }

    private func completeRequest<T>(_ request: NetworkRequest,
                                    response: DataResponse<T>,
                                    success: @escaping Success<T>,
                                    failure: @escaping Failure) {
        let generalResponse = GeneralResponse(request: request, dataResponse: response)
        let callback = RequestCallback(success: success, failure: failure)
        responseHandlingService?.handleResponse(generalResponse, callback: callback)
    }
}
