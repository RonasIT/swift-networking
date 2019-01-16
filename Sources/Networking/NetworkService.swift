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
    private let errorHandlingService: ErrorHandlingServiceProtocol?

    private var activeRequests: [String: Request] = [:]

    public init(sessionManager: SessionManager = .default,
                requestAdaptingService: RequestAdaptingServiceProtocol? = nil,
                errorHandlingService: ErrorHandlingServiceProtocol? = nil) {
        self.sessionManager = sessionManager
        self.requestAdaptingService = requestAdaptingService
        self.errorHandlingService = errorHandlingService
    }

    @discardableResult
    public func response(for endpoint: Endpoint,
                         encoding: String.Encoding? = nil,
                         success: @escaping Success<String>,
                         failure: @escaping Failure) -> CancellableRequest {
        let serializer = DataRequest.stringResponseSerializer(encoding: encoding)
        return response(for: endpoint, serializer: serializer, success: success, failure: failure)
    }

    @discardableResult
    public func response(for endpoint: Endpoint,
                         success: @escaping Success<Data>,
                         failure: @escaping Failure) -> CancellableRequest {
        let serializer = DataRequest.dataResponseSerializer()
        return response(for: endpoint, serializer: serializer, success: success, failure: failure)
    }

    @discardableResult
    public func response<Object>(for endpoint: Endpoint,
                                 decoder: JSONDecoder = JSONDecoder(),
                                 success: @escaping Success<Object>,
                                 failure: @escaping Failure) -> CancellableRequest where Object: Decodable {
        let serializer: DataResponseSerializer<Object> = DataRequest.decodableResponseSerializer(with: decoder)
        return response(for: endpoint, serializer: serializer, success: success, failure: failure)
    }

    @discardableResult
    public func response<Key, Value>(for endpoint: Endpoint,
                                     readingOptions: JSONSerialization.ReadingOptions = .allowFragments,
                                     success: @escaping Success<[Key: Value]>,
                                     failure: @escaping Failure) -> CancellableRequest where Key: Hashable, Value: Any {
        let serializer: DataResponseSerializer<[Key: Value]> = DataRequest.jsonResponseSerializer(with: readingOptions)
        return response(for: endpoint, serializer: serializer, success: success, failure: failure)
    }

    @discardableResult
    public func response(for uploadEndpoint: UploadEndpoint,
                         encoding: String.Encoding? = nil,
                         success: @escaping Success<String>,
                         failure: @escaping Failure) -> CancellableRequest {
        let serializer = DataRequest.stringResponseSerializer(encoding: encoding)
        return response(for: uploadEndpoint, serializer: serializer, success: success, failure: failure)
    }

    @discardableResult
    public func response(for uploadEndpoint: UploadEndpoint,
                         success: @escaping Success<Data>,
                         failure: @escaping Failure) -> CancellableRequest {
        let serializer = DataRequest.dataResponseSerializer()
        return response(for: uploadEndpoint, serializer: serializer, success: success, failure: failure)
    }

    @discardableResult
    public func response<Object>(for uploadEndpoint: UploadEndpoint,
                                 decoder: JSONDecoder = JSONDecoder(),
                                 success: @escaping Success<Object>,
                                 failure: @escaping Failure) -> CancellableRequest where Object: Decodable {
        let serializer: DataResponseSerializer<Object> = DataRequest.decodableResponseSerializer(with: decoder)
        return response(for: uploadEndpoint, serializer: serializer, success: success, failure: failure)
    }

    @discardableResult
    public func response<Key, Value>(for uploadEndpoint: UploadEndpoint,
                                     readingOptions: JSONSerialization.ReadingOptions = .allowFragments,
                                     success: @escaping Success<[Key: Value]>,
                                     failure: @escaping Failure) -> CancellableRequest where Key: Hashable, Value: Any {
        let serializer: DataResponseSerializer<[Key: Value]> = DataRequest.jsonResponseSerializer(with: readingOptions)
        return response(for: uploadEndpoint, serializer: serializer, success: success, failure: failure)
    }

    // MARK: - Private

    private func response<Result>(for endpoint: Endpoint,
                                  serializer: DataResponseSerializer<Result>,
                                  success: @escaping Success<Result>,
                                  failure: @escaping Failure) -> CancellableRequest {
        let request = NetworkRequest(sessionManager: sessionManager, endpoint: endpoint)
        return response(for: request, serializer: serializer, success: success, failure: failure)
    }

    private func response<Result>(for endpoint: UploadEndpoint,
                                  serializer: DataResponseSerializer<Result>,
                                  success: @escaping Success<Result>,
                                  failure: @escaping Failure) -> CancellableRequest {
        let request = NetworkUploadRequest(sessionManager: sessionManager, endpoint: endpoint)
        return response(for: request, serializer: serializer, success: success, failure: failure)
    }

    private func response<Result>(for request: Request,
                                  serializer: DataResponseSerializer<Result>,
                                  success: @escaping Success<Result>,
                                  failure: @escaping Failure) -> CancellableRequest {
        requestAdaptingService?.adapt(request)

        // Strong reference to request in response handler causes retain cycle (request <-> response handler)
        // To solve issue reference to request will be temporary stored in `activeRequests` and removed in
        // response handler execution
        activeRequests[request.id] = request
        request.response(queue: nil, responseSerializer: serializer) { [weak self, weak request] response in
            guard let `request` = request else {
                return
            }
            self?.activeRequests[request.id] = nil
            self?.handleResponse(response, of: request, success: success, failure: failure)
        }
        return request
    }

    private func handleResponse<T>(_ response: DataResponse<T>,
                                   of request: Request,
                                   success: @escaping Success<T>,
                                   failure: @escaping Failure) {
        switch response.result {
        case .failure(let error):
            guard let errorHandlingService = errorHandlingService else {
                failure(error)
                return
            }
            errorHandlingService.handleError(error) { result in
                switch result {
                case .failure(let error):
                    failure(error)
                case .errorResolved:
                    request.retry()
                }
            }
        case .success(let result):
            success(result)
        }
    }
}
