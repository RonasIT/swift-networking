//
// Created by Nikita Zatsepilov on 03/12/2018.
// Copyright (c) 2018 Ronas IT. All rights reserved.
//

import Foundation
import Alamofire

final class GeneralUploadRequest: Request, RequestErrorHandling, RequestResponseHandling {

    public let endpoint: Endpoint
    public var auth: RequestAuth = .none
    public var errorHandlers: [ErrorHandler] = []

    private let sessionManager: SessionManager
    private let httpHeadersFactory: HTTPHeadersFactory
    private let imageBodyParts: [ImageBodyPart]

    private var request: DataRequest?
    private var isCancelled: Bool = false

    init(endpoint: Endpoint,
         sessionManager: SessionManager = SessionManager.default,
         httpHeadersFactory: HTTPHeadersFactory,
         imageBodyParts: [ImageBodyPart]) {
        self.endpoint = endpoint
        self.sessionManager = sessionManager
        self.httpHeadersFactory = httpHeadersFactory
        self.imageBodyParts = imageBodyParts
    }

    func responseString(successHandler: @escaping SuccessHandler<String>,
                        failureHandler: @escaping FailureHandler) {
        makeRequest(success: { [weak self] request in
            guard let `self` = self else {
                return
            }

            self.request = request.responseString { response in
                switch response.result {
                case .failure(let error):
                    self.handleError(error, for: response, failureHandler: failureHandler)
                case .success(let string):
                    self.handleResponseString(string, successHandler: successHandler, failureHandler: failureHandler)
                }
            }
        }, failure: { [weak self] error in
            self?.handleError(error, failureHandler: failureHandler)
        })
    }

    func responseDecodableObject<Object: Decodable>(with decoder: JSONDecoder = JSONDecoder(),
                                                    successHandler: @escaping SuccessHandler<Object>,
                                                    failureHandler: @escaping FailureHandler) {
        makeRequest(success: { [weak self] request in
            guard let `self` = self else {
                return
            }

            self.request = request.responseData { response in
                switch response.result {
                case .failure(let error):
                    self.handleError(error, for: response, failureHandler: failureHandler)
                case .success(let data):
                    self.handleResponseDecodableObject(with: data,
                                                       decoder: decoder,
                                                       successHandler: successHandler,
                                                       failureHandler: failureHandler)
                }
            }
        }, failure: { [weak self] error in
            self?.handleError(error, failureHandler: failureHandler)
        })
    }

    func responseJSON(with readingOptions: JSONSerialization.ReadingOptions = .allowFragments,
                      successHandler: @escaping SuccessHandler<Any>,
                      failureHandler: @escaping FailureHandler) {
        makeRequest(success: { [weak self] request in
            guard let `self` = self else {
                return
            }

            self.request = request.responseJSON(options: readingOptions) { response in
                switch response.result {
                case .failure(let error):
                    self.handleError(error, for: response, failureHandler: failureHandler)
                case .success(let json):
                    self.handleResponseJSON(json, successHandler: successHandler, failureHandler: failureHandler)
                }
            }
        }, failure: { [weak self] error in
            self?.handleError(error, failureHandler: failureHandler)
        })
    }

    func responseData(successHandler: @escaping SuccessHandler<Data>,
                      failureHandler: @escaping FailureHandler) {
        makeRequest(success: { [weak self] request in
            guard let `self` = self else {
                return
            }

            self.request = request.responseData { response in
                switch response.result {
                case .failure(let error):
                    self.handleError(error, for: response, failureHandler: failureHandler)
                case .success(let data):
                    self.handleResponseData(data, successHandler: successHandler, failureHandler: failureHandler)
                }
            }
        }, failure: { [weak self] error in
            self?.handleError(error, failureHandler: failureHandler)
        })
    }

    func cancel() {
        isCancelled = true
        request?.cancel()
    }

    // MARK: - Private

    private func makeRequest(success: @escaping (DataRequest) -> Void, failure: @escaping (Error) -> Void) {
        let multipartFormDataHandler = { [weak self] (multipartFormData: MultipartFormData) in
            guard let `self` = self else {
                return
            }
            multipartFormData.appendImageBodyParts(self.imageBodyParts)
            if let parameters = self.endpoint.parameters {
                multipartFormData.appendParametersBodyParts(parameters)
            }
        }
        let encodingCompletion = { [weak self] (encodingResult: SessionManager.MultipartFormDataEncodingResult) in
            guard let `self` = self, !self.isCancelled else {
                return
            }
            switch encodingResult {
            case .success(let request, _, _):
                request.validate()
                success(request)
            case .failure(let error):
                failure(error)
            }
        }
        sessionManager.upload(multipartFormData: multipartFormDataHandler,
                              usingThreshold: SessionManager.multipartFormDataEncodingMemoryThreshold,
                              to: endpoint.url,
                              method: .post,
                              headers: endpoint.headers.httpHeaders,
                              encodingCompletion: encodingCompletion)
    }

    private func handleError(_ error: Error, failureHandler: @escaping FailureHandler) {
        // Pass `DataResponse<T>?` as `nil`
        // swiftlint:disable:next syntactic_sugar
        let response = Optional<DataResponse<Any>>(nilLiteral: ())
        handleError(error, for: response, failureHandler: failureHandler)
    }
}
