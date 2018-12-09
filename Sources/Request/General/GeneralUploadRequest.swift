//
// Created by Nikita Zatsepilov on 03/12/2018.
// Copyright (c) 2018 Ronas IT. All rights reserved.
//

import Alamofire

final class GeneralUploadRequest: NetworkRequest, CancellableRequest {

    public let endpoint: Endpoint

    let identifier: String = UUID().uuidString
    var headers: [RequestHeader] = []

    private let sessionManager: SessionManager
    private let imageBodyParts: [ImageBodyPart]

    private var request: DataRequest?
    private var isCancelled: Bool = false

    private var sending: (() -> Void)?

    init(sessionManager: SessionManager = SessionManager.default,
         endpoint: UploadEndpoint) {
        self.sessionManager = sessionManager
        self.endpoint = endpoint
        headers = endpoint.headers
        imageBodyParts = endpoint.imageBodyParts
    }

    func responseData(queue: DispatchQueue? = nil, completion: @escaping Completion<DataResponse<Data>>) {
        makeRequest(success: { request in
            self.request = request
            self.sending = {
                request.responseData(queue: queue, completionHandler: completion)
            }
            self.sending?()
        }, failure: { error in
            completion(self.emptyResponse(for: error))
        })
    }

    func responseJSON<Key: Hashable, Value>(queue: Dispatch.DispatchQueue? = nil,
                                            readingOptions: JSONSerialization.ReadingOptions,
                                            completion: @escaping Completion<DataResponse<[Key: Value]>>) {
        makeRequest(success: { request in
            self.request = request
            self.sending = {
                request.responseJSON(queue: queue, readingOptions: readingOptions, completionHandler: completion)
            }
            self.sending?()
        }, failure: { error in
            completion(self.emptyResponse(for: error))
        })
    }

    func responseString(queue: DispatchQueue? = nil,
                        encoding: String.Encoding?,
                        completion: @escaping Completion<DataResponse<String>>) {
        makeRequest(success: { request in
            self.request = request
            self.sending = {
                request.responseString(queue: queue, encoding: encoding, completionHandler: completion)
            }
            self.sending?()
        }, failure: { error in
            completion(self.emptyResponse(for: error))
        })
    }

    func responseObject<Object: Decodable>(queue: DispatchQueue? = nil,
                                           decoder: JSONDecoder,
                                           completion: @escaping Completion<DataResponse<Object>>) {
        makeRequest(success: { request in
            self.request = request
            self.sending = {
                request.responseObject(queue: queue, decoder: decoder, completionHandler: completion)
            }
            self.sending?()
        }, failure: { error in
            completion(self.emptyResponse(for: error))
        })
    }

    func cancel() {
        isCancelled = true
        request?.cancel()
        request = nil
        sending = nil
    }

    func retry() {
        isCancelled = false
        sending?()
    }

    // MARK: - Private

    private func makeRequest(success: @escaping (DataRequest) -> Void, failure: @escaping (Error) -> Void) {
        let multipartFormDataHandler = { (multipartFormData: MultipartFormData) in
            multipartFormData.appendImageBodyParts(self.imageBodyParts)
            if let parameters = self.endpoint.parameters {
                multipartFormData.appendParametersBodyParts(parameters)
            }
        }
        let encodingCompletion = { (encodingResult: SessionManager.MultipartFormDataEncodingResult) in
            guard !self.isCancelled else {
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
                              headers: headers.httpHeaders,
                              encodingCompletion: encodingCompletion)
    }

    private func emptyResponse<T>(for error: Error) -> DataResponse<T> {
        return DataResponse<T>(request: nil, response: nil, data: nil, result: .failure(error))
    }
}
