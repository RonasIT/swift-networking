//
//  Created by Dmitry Frishbuter on 27/09/2018
//  Copyright © 2018 Ronas IT. All rights reserved.
//

import Foundation
import Alamofire

public typealias ProgressHandler = Alamofire.DownloadRequest.ProgressHandler
public typealias SuccessHandler<T> = (T) -> Void
public typealias FailureHandler = (Error) -> Void

open class NetworkService: NSObject {

    private enum Error: LocalizedError {
        case invalidHTTPResponse

        var errorDescription: String? {
            switch self {
            case .invalidHTTPResponse:
                return "⚠️ Received invalid HTTP response"
            }
        }
    }

    private let session: Alamofire.Session
    private let requestAdaptingService: RequestAdaptingServiceProtocol?
    private let errorHandlingService: ErrorHandlingServiceProtocol?

    public init(session: Alamofire.Session = .default,
                requestAdaptingService: RequestAdaptingServiceProtocol? = nil,
                errorHandlingService: ErrorHandlingServiceProtocol? = nil) {
        self.session = session
        self.requestAdaptingService = requestAdaptingService
        self.errorHandlingService = errorHandlingService
    }

    final func send<Response>(_ request: Request,
                              responseSerializer: AnyResponseSerializer<Response>,
                              success: @escaping SuccessHandler<Response>,
                              failure: @escaping FailureHandler) -> CancellableRequest {
        requestAdaptingService?.adapt(request)
        request.response { [weak self] request, response in
            guard let self = self else {
                return
            }

            func fail(with error: Swift.Error) {
                self.handleError(error, response: response, request: request, failure: failure)
            }

            switch response.result {
            case .failure(let error):
                fail(with: error)
            case .success(let result):
                guard let httpResponse = response.response else {
                    fail(with: Error.invalidHTTPResponse)
                    return
                }

                let dataResponse = DataResponse(result: result, httpResponse: httpResponse)

                do {
                    success(try responseSerializer.serialize(dataResponse))
                } catch {
                    fail(with: error)
                }
            }
        }
        return request
    }

    // MARK: -  Requests with custom response serializer

    public func request<Response>(for endpoint: Endpoint,
                                  responseSerializer: AnyResponseSerializer<Response>,
                                  success: @escaping SuccessHandler<Response>,
                                  failure: @escaping FailureHandler) -> CancellableRequest {
        return send(
            Request(session: session, endpoint: endpoint),
            responseSerializer: responseSerializer,
            success: success,
            failure: failure
        )
    }

    public func uploadRequest<Response>(for endpoint: UploadEndpoint,
                                        responseSerializer: AnyResponseSerializer<Response>,
                                        progress: ProgressHandler? = nil,
                                        success: @escaping SuccessHandler<Response>,
                                        failure: @escaping FailureHandler) -> CancellableRequest {
        let request = UploadRequest(session: session, endpoint: endpoint)
        request.progress = progress
        return send(
            request,
            responseSerializer: responseSerializer,
            success: success,
            failure: failure
        )
    }

    // MARK: -  Data

    @discardableResult
    public func request(for endpoint: Endpoint,
                        success: @escaping SuccessHandler<DataResponse>,
                        failure: @escaping FailureHandler) -> CancellableRequest {
        let responseSerializer = AnyResponseSerializer { $0 }
        return request(
            for: endpoint,
            responseSerializer: responseSerializer,
            success: success,
            failure: failure
        )
    }

    @discardableResult
    public func request(for endpoint: Endpoint,
                        success: @escaping SuccessHandler<Data>,
                        failure: @escaping FailureHandler) -> CancellableRequest {
        return request(for: endpoint, success: { (response: DataResponse) in
            success(response.result)
        }, failure: failure)
    }

    @discardableResult
    public final func uploadRequest(for endpoint: UploadEndpoint,
                                    progress: ProgressHandler? = nil,
                                    success: @escaping SuccessHandler<DataResponse>,
                                    failure: @escaping FailureHandler) -> CancellableRequest {
        let responseSerializer = AnyResponseSerializer { $0 }
        return uploadRequest(
            for: endpoint,
            responseSerializer: responseSerializer,
            progress: progress,
            success: success,
            failure: failure
        )
    }

    @discardableResult
    public final func uploadRequest(for endpoint: UploadEndpoint,
                                    success: @escaping SuccessHandler<Data>,
                                    failure: @escaping FailureHandler) -> CancellableRequest {
        return uploadRequest(for: endpoint, success: { (response: DataResponse) in
            success(response.result)
        }, failure: failure)
    }

    // MARK: -  String

    @discardableResult
    public final func request(for endpoint: Endpoint,
                              encoding: StringResponseSerializer.Encoding = .automatic,
                              success: @escaping SuccessHandler<StringResponse>,
                              failure: @escaping FailureHandler) -> CancellableRequest {
        let responseSerializer = StringResponseSerializer(encoding: encoding).typeErased()
        return request(
            for: endpoint,
            responseSerializer: responseSerializer,
            success: success,
            failure: failure
        )
    }

    @discardableResult
    public final func request(for endpoint: Endpoint,
                              encoding: StringResponseSerializer.Encoding = .automatic,
                              success: @escaping SuccessHandler<String>,
                              failure: @escaping FailureHandler) -> CancellableRequest {
        return request(for: endpoint, encoding: encoding, success: { response in
            success(response.result)
        }, failure: failure)
    }

    @discardableResult
    public final func uploadRequest(for endpoint: UploadEndpoint,
                                    encoding: StringResponseSerializer.Encoding = .automatic,
                                    progress: ProgressHandler? = nil,
                                    success: @escaping SuccessHandler<StringResponse>,
                                    failure: @escaping FailureHandler) -> CancellableRequest {
        let responseSerializer = StringResponseSerializer(encoding: encoding).typeErased()
        return uploadRequest(
            for: endpoint,
            responseSerializer: responseSerializer,
            progress: progress,
            success: success,
            failure: failure
        )
    }

    @discardableResult
    public final func uploadRequest(for endpoint: UploadEndpoint,
                                    encoding: StringResponseSerializer.Encoding = .automatic,
                                    progress: ProgressHandler? = nil,
                                    success: @escaping SuccessHandler<String>,
                                    failure: @escaping FailureHandler) -> CancellableRequest {
        return uploadRequest(
            for: endpoint,
            encoding: encoding,
            progress: progress,
            success: { response in
                success(response.result)
            },
            failure: failure
        )
    }

    // MARK: -  Decodable

    @discardableResult
    public final func request<Result>(for endpoint: Endpoint,
                                      decoder: JSONDecoder = JSONDecoder(),
                                      success: @escaping SuccessHandler<DecodableResponse<Result>>,
                                      failure: @escaping FailureHandler) -> CancellableRequest {
        let responseSerializer = DecodableResponseSerializer<Result>(decoder: decoder).typeErased()
        return request(
            for: endpoint,
            responseSerializer: responseSerializer,
            success: success,
            failure: failure
        )
    }

    @discardableResult
    public final func request<Result: Decodable>(for endpoint: Endpoint,
                                                 decoder: JSONDecoder = JSONDecoder(),
                                                 success: @escaping SuccessHandler<Result>,
                                                 failure: @escaping FailureHandler) -> CancellableRequest {
        return request(for: endpoint, decoder: decoder, success: { response in
            success(response.result)
        }, failure: failure)
    }

    @discardableResult
    public final func uploadRequest<Result>(for endpoint: UploadEndpoint,
                                            decoder: JSONDecoder = JSONDecoder(),
                                            progress: ProgressHandler? = nil,
                                            success: @escaping SuccessHandler<DecodableResponse<Result>>,
                                            failure: @escaping FailureHandler) -> CancellableRequest {
        let responseSerializer = DecodableResponseSerializer<Result>(decoder: decoder).typeErased()
        return uploadRequest(
            for: endpoint,
            responseSerializer: responseSerializer,
            progress: progress,
            success: success,
            failure: failure
        )
    }

    @discardableResult
    public final func uploadRequest<Result: Decodable>(for endpoint: UploadEndpoint,
                                                       decoder: JSONDecoder = JSONDecoder(),
                                                       progress: ProgressHandler? = nil,
                                                       success: @escaping SuccessHandler<Result>,
                                                       failure: @escaping FailureHandler) -> CancellableRequest {
        return uploadRequest(
            for: endpoint,
            decoder: decoder,
            progress: progress,
            success: { response in
                success(response.result)
            },
            failure: failure
        )
    }

    // MARK: -  JSON

    @discardableResult
    public final func request(for endpoint: Endpoint,
                              readingOptions: JSONSerialization.ReadingOptions = .allowFragments,
                              success: @escaping SuccessHandler<JSONResponse>,
                              failure: @escaping FailureHandler) -> CancellableRequest {
        let responseSerializer = JSONResponseSerializer(readingOptions: readingOptions).typeErased()
        return request(
            for: endpoint,
            responseSerializer: responseSerializer,
            success: success,
            failure: failure
        )
    }

    @discardableResult
    public final func request(for endpoint: Endpoint,
                              readingOptions: JSONSerialization.ReadingOptions = .allowFragments,
                              success: @escaping SuccessHandler<[String: Any]>,
                              failure: @escaping FailureHandler) -> CancellableRequest {
        return request(for: endpoint, readingOptions: readingOptions, success: { response in
            success(response.result)
        }, failure: failure)
    }

    @discardableResult
    public final func uploadRequest(for endpoint: UploadEndpoint,
                                    readingOptions: JSONSerialization.ReadingOptions = .allowFragments,
                                    success: @escaping SuccessHandler<JSONResponse>,
                                    failure: @escaping FailureHandler) -> CancellableRequest {
        let responseSerializer = JSONResponseSerializer(readingOptions: readingOptions).typeErased()
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
                                    success: @escaping SuccessHandler<[String: Any]>,
                                    failure: @escaping FailureHandler) -> CancellableRequest {
        return uploadRequest(for: endpoint, readingOptions: readingOptions, success: { response in
            success(response.result)
        }, failure: failure)
    }

    // MARK: -  Empty

    @discardableResult
    public final func request(for endpoint: Endpoint,
                              success: @escaping (EmptyResponse) -> Void,
                              failure: @escaping FailureHandler) -> CancellableRequest {
        return request(for: endpoint, success: { (response: DataResponse) in
            success(response.empty)
        }, failure: { error in
            failure(error)
        })
    }

    @discardableResult
    public final func request(for endpoint: Endpoint,
                              success: @escaping () -> Void,
                              failure: @escaping FailureHandler) -> CancellableRequest {
        return request(for: endpoint, success: { (_: DataResponse) in
            success()
        }, failure: failure)
    }

    @discardableResult
    public func uploadRequest(for endpoint: UploadEndpoint,
                              progress: ProgressHandler? = nil,
                              success: @escaping (EmptyResponse) -> Void,
                              failure: @escaping FailureHandler) -> CancellableRequest {
        return uploadRequest(for: endpoint, progress: progress, success: { (response: DataResponse) in
            success(response.empty)
        }, failure: failure)
    }

    @discardableResult
    public final func uploadRequest(for endpoint: UploadEndpoint,
                                    success: @escaping () -> Void,
                                    failure: @escaping FailureHandler) -> CancellableRequest {
        return uploadRequest(for: endpoint, success: { (_: DataResponse) in
            success()
        }, failure: failure)
    }

    // MARK: -  Private

    private func handleError(_ error: Swift.Error,
                             response: AFDataResponse<Data>,
                             request: RetryableRequest,
                             failure: @escaping FailureHandler) {
        guard let errorHandlingService = errorHandlingService else {
            failure(error)
            return
        }
        let payload = ErrorPayload(endpoint: request.endpoint, error: error, response: response)
        errorHandlingService.handleError(with: payload, retrying: { [weak self] in
            guard let self = self else {
                return
            }
            self.requestAdaptingService?.adapt(request)
            request.retry()
        }, failure: failure)
    }
}
