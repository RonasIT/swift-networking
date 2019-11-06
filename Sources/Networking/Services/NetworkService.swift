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

    public init(sessionManager: SessionManager = .default,
                requestAdaptingService: RequestAdaptingServiceProtocol? = nil,
                errorHandlingService: ErrorHandlingServiceProtocol? = nil) {
        self.sessionManager = sessionManager
        self.requestAdaptingService = requestAdaptingService
        self.errorHandlingService = errorHandlingService
    }

    func request<Result>(for endpoint: Endpoint,
                         responseSerializer: DataResponseSerializer<Result>,
                         success: @escaping Success<Result>,
                         failure: @escaping Failure) -> CancellableRequest {
        let request = Request(
            sessionManager: sessionManager,
            endpoint: endpoint,
            responseSerializer: responseSerializer
        )
        return response(for: request, success: success, failure: failure)
    }

    func uploadRequest<Result>(for endpoint: UploadEndpoint,
                               responseSerializer: DataResponseSerializer<Result>,
                               success: @escaping Success<Result>,
                               failure: @escaping Failure) -> CancellableRequest {
        let request = UploadRequest(
            sessionManager: sessionManager,
            endpoint: endpoint,
            responseSerializer: responseSerializer
        )
        return response(for: request, success: success, failure: failure)
    }

    final func response<Result>(for request: Request<Result>,
                                success: @escaping Success<Result>,
                                failure: @escaping Failure) -> CancellableRequest {
        requestAdaptingService?.adapt(request)
        request.response { [weak self] (request: RetryableRequest, response: DataResponse<Result>) in
            guard let self = self else {
                return
            }
            switch response.result {
            case .failure(let error):
                self.handleResponseError(error, response: response, request: request, failure: failure)
            case .success(let result):
                success(result)
            }
        }
        return request
    }

    // MARK: - Requests

    @discardableResult
    public final func request(for endpoint: Endpoint,
                              encoding: String.Encoding? = nil,
                              success: @escaping Success<String>,
                              failure: @escaping Failure) -> CancellableRequest {
        let responseSerializer = DataRequest.stringResponseSerializer(encoding: encoding)
        return request(for: endpoint, responseSerializer: responseSerializer, success: success, failure: failure)
    }

    @discardableResult
    public func request(for endpoint: Endpoint,
                        success: @escaping Success<Data>,
                        failure: @escaping Failure) -> CancellableRequest {
        let responseSerializer = DataRequest.dataResponseSerializer()
        return request(for: endpoint, responseSerializer: responseSerializer, success: success, failure: failure)
    }

    @discardableResult
    public final func request<Object>(for endpoint: Endpoint,
                                      decoder: JSONDecoder = JSONDecoder(),
                                      success: @escaping Success<Object>,
                                      failure: @escaping Failure) -> CancellableRequest where Object: Decodable {
        let responseSerializer: DecodableResponseSerializer<Object> = .init(decoder: decoder)
        let dataResponseSerializer = responseSerializer.asDataResponseSerializer()
        return request(for: endpoint, responseSerializer: dataResponseSerializer, success: success, failure: failure)
    }

    @discardableResult
    public final func request(for endpoint: Endpoint,
                              readingOptions: JSONSerialization.ReadingOptions = .allowFragments,
                              success: @escaping Success<[String: Any]>,
                              failure: @escaping Failure) -> CancellableRequest {
        let responseSerializer = JSONResponseSerializer(readingOptions: readingOptions)
        let dataResponseSerializer = responseSerializer.asDataResponseSerializer()
        return request(for: endpoint, responseSerializer: dataResponseSerializer, success: success, failure: failure)
    }

    @discardableResult
    public final func request(for endpoint: Endpoint,
                              success: @escaping () -> Void,
                              failure: @escaping Failure) -> CancellableRequest {
        let responseSerializer = DataRequest.dataResponseSerializer()
        return request(for: endpoint, responseSerializer: responseSerializer, success: { _ in
            success()
        }, failure: failure)
    }

    @discardableResult
    public final func request(for endpoint: Endpoint,
                              encoding: String.Encoding? = nil,
                              success: @escaping Success<DetailedResponse<String>>,
                              failure: @escaping Failure) -> CancellableRequest {
        let serializer = DataRequest.stringResponseSerializer(encoding: encoding)
        let responseSerializer = DetailedResponseSerializer(serializer: serializer).asDataResponseSerializer()
        return request(for: endpoint, responseSerializer: responseSerializer, success: success, failure: failure)
    }

    @discardableResult
    public func request(for endpoint: Endpoint,
                        success: @escaping Success<DetailedResponse<Data>>,
                        failure: @escaping Failure) -> CancellableRequest {
        let serializer = DataRequest.dataResponseSerializer()
        let responseSerializer = DetailedResponseSerializer(serializer: serializer).asDataResponseSerializer()
        return request(for: endpoint, responseSerializer: responseSerializer, success: success, failure: failure)
    }

    @discardableResult
    public final func request<Object>(for endpoint: Endpoint,
                                      decoder: JSONDecoder = JSONDecoder(),
                                      success: @escaping Success<DetailedResponse<Object>>,
                                      failure: @escaping Failure) -> CancellableRequest where Object: Decodable {
        let serializer: DecodableResponseSerializer<Object> = .init(decoder: decoder)
        let responseSerializer = DetailedResponseSerializer(serializer: serializer).asDataResponseSerializer()
        return request(for: endpoint, responseSerializer: responseSerializer, success: success, failure: failure)
    }

    @discardableResult
    public final func request(for endpoint: Endpoint,
                              readingOptions: JSONSerialization.ReadingOptions = .allowFragments,
                              success: @escaping Success<DetailedResponse<[String: Any]>>,
                              failure: @escaping Failure) -> CancellableRequest {
        let serializer = JSONResponseSerializer(readingOptions: readingOptions).asDataResponseSerializer()
        let responseSerializer = DetailedResponseSerializer(serializer: serializer).asDataResponseSerializer()
        return request(for: endpoint, responseSerializer: responseSerializer, success: success, failure: failure)
    }

    @discardableResult
    public final func request(for endpoint: Endpoint,
                              success: @escaping Success<DetailedEmptyResponse>,
                              failure: @escaping Failure) -> CancellableRequest {
        let serializer = DataRequest.dataResponseSerializer()
        let responseSerializer = DetailedResponseSerializer(serializer: serializer).asDataResponseSerializer()
        return request(
            for: endpoint,
            responseSerializer: responseSerializer,
            success: { response in
                success(DetailedEmptyResponse(response: response))
            },
            failure: failure
        )
    }

    // MARK: - Upload requests

    @discardableResult
    public final func uploadRequest(for endpoint: UploadEndpoint,
                                    encoding: String.Encoding? = nil,
                                    success: @escaping Success<String>,
                                    failure: @escaping Failure) -> CancellableRequest {
        let responseSerializer = DataRequest.stringResponseSerializer(encoding: encoding)
        return uploadRequest(
            for: endpoint,
            responseSerializer: responseSerializer,
            success: success,
            failure: failure
        )
    }

    @discardableResult
    public final func uploadRequest(for endpoint: UploadEndpoint,
                                    success: @escaping Success<Data>,
                                    failure: @escaping Failure) -> CancellableRequest {
        let responseSerializer = DataRequest.dataResponseSerializer()
        return uploadRequest(
            for: endpoint,
            responseSerializer: responseSerializer,
            success: success,
            failure: failure
        )
    }

    @discardableResult
    public final func uploadRequest<Object>(for endpoint: UploadEndpoint,
                                            decoder: JSONDecoder = JSONDecoder(),
                                            success: @escaping Success<Object>,
                                            failure: @escaping Failure) -> CancellableRequest where Object: Decodable {
        let responseSerializer: DecodableResponseSerializer<Object> = .init(decoder: decoder)
        let dataResponseSerializer = responseSerializer.asDataResponseSerializer()
        return uploadRequest(
            for: endpoint,
            responseSerializer: dataResponseSerializer,
            success: success,
            failure: failure
        )
    }

    @discardableResult
    public final func uploadRequest(for endpoint: UploadEndpoint,
                                    readingOptions: JSONSerialization.ReadingOptions = .allowFragments,
                                    success: @escaping Success<[String: Any]>,
                                    failure: @escaping Failure) -> CancellableRequest {
        let responseSerializer = JSONResponseSerializer(readingOptions: readingOptions)
        let dataResponseSerializer = responseSerializer.asDataResponseSerializer()
        return uploadRequest(
            for: endpoint,
            responseSerializer: dataResponseSerializer,
            success: success,
            failure: failure
        )
    }

    @discardableResult
    public final func uploadRequest(for endpoint: UploadEndpoint,
                                    success: @escaping () -> Void,
                                    failure: @escaping Failure) -> CancellableRequest {
        let responseSerializer = DataRequest.dataResponseSerializer()
        return uploadRequest(for: endpoint, responseSerializer: responseSerializer, success: { _ in
            success()
        }, failure: failure)
    }

    @discardableResult
    public final func uploadRequest(for endpoint: UploadEndpoint,
                                    encoding: String.Encoding? = nil,
                                    success: @escaping Success<DetailedResponse<String>>,
                                    failure: @escaping Failure) -> CancellableRequest {
        let serializer = DataRequest.stringResponseSerializer(encoding: encoding)
        let responseSerializer = DetailedResponseSerializer(serializer: serializer).asDataResponseSerializer()
        return uploadRequest(
            for: endpoint,
            responseSerializer: responseSerializer,
            success: success,
            failure: failure
        )
    }

    @discardableResult
    public final func uploadRequest(for endpoint: UploadEndpoint,
                                    success: @escaping Success<DetailedResponse<Data>>,
                                    failure: @escaping Failure) -> CancellableRequest {
        let serializer = DataRequest.dataResponseSerializer()
        let responseSerializer = DetailedResponseSerializer(serializer: serializer).asDataResponseSerializer()
        return uploadRequest(
            for: endpoint,
            responseSerializer: responseSerializer,
            success: success,
            failure: failure
        )
    }

    @discardableResult
    public final func uploadRequest<Object>(for endpoint: UploadEndpoint,
                                            decoder: JSONDecoder = JSONDecoder(),
                                            success: @escaping Success<DetailedResponse<Object>>,
                                            failure: @escaping Failure) -> CancellableRequest where Object: Decodable {
        let serializer: DecodableResponseSerializer<Object> = .init(decoder: decoder)
        let responseSerializer = DetailedResponseSerializer(serializer: serializer).asDataResponseSerializer()
        return uploadRequest(
            for: endpoint,
            responseSerializer: responseSerializer,
            success: success,
            failure: failure
        )
    }

    @discardableResult
    public final func uploadRequest(for endpoint: UploadEndpoint,
                                    readingOptions: JSONSerialization.ReadingOptions = .allowFragments,
                                    success: @escaping Success<DetailedResponse<[String: Any]>>,
                                    failure: @escaping Failure) -> CancellableRequest {
        let serializer = JSONResponseSerializer(readingOptions: readingOptions)
        let responseSerializer = DetailedResponseSerializer(serializer: serializer).asDataResponseSerializer()
        return uploadRequest(
            for: endpoint,
            responseSerializer: responseSerializer,
            success: success,
            failure: failure
        )
    }

    @discardableResult
    public final func uploadRequest(for endpoint: UploadEndpoint,
                                    success: @escaping Success<DetailedEmptyResponse>,
                                    failure: @escaping Failure) -> CancellableRequest {
        let serializer = DataRequest.dataResponseSerializer()
        let responseSerializer = DetailedResponseSerializer(serializer: serializer).asDataResponseSerializer()
        return uploadRequest(for: endpoint, responseSerializer: responseSerializer, success: { response in
            success(DetailedEmptyResponse(response: response))
        }, failure: failure)
    }

    // MARK: - Private

    private func handleResponseError<Result>(_ error: Error,
                                             response: DataResponse<Result>,
                                             request: RetryableRequest,
                                             failure: @escaping Failure) {
        guard let errorHandlingService = errorHandlingService else {
            failure(error)
            return
        }

        let requestError = RequestError(endpoint: request.endpoint, error: error, response: response)
        errorHandlingService.handleError(requestError, retrying: { [weak self] in
            guard let self = self else {
                return
            }
            self.requestAdaptingService?.adapt(request)
            request.retry()
        }, failure: failure)
    }
}
