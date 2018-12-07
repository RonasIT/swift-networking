//
// Created by Nikita Zatsepilov on 03/12/2018.
// Copyright (c) 2018 Ronas IT. All rights reserved.
//

import Foundation
import Alamofire

// FIXME: requires ARC check

final class GeneralUploadRequest: NetworkRequest {

    public let endpoint: Endpoint

    private(set) var additionalHeaders: [RequestHeader] = []

    private let sessionManager: SessionManager
    private let imageBodyParts: [ImageBodyPart]

    private var request: DataRequest?
    private var isCancelled: Bool = false

    init(sessionManager: SessionManager = SessionManager.default,
         endpoint: UploadEndpoint) {
        self.sessionManager = sessionManager
        self.endpoint = endpoint
        imageBodyParts = endpoint.imageBodyParts
    }

    func responseData(queue: DispatchQueue? = nil, completion: @escaping Completion<DataResponse<Data>>) {
        makeRequest(success: { request in
            self.request = request.responseData(queue: queue, completionHandler: completion)
        }, failure: { error in
            completion(self.errorResponse(with: error))
        })
    }

    func responseJSON<Key: Hashable, Value>(queue: Dispatch.DispatchQueue? = nil,
                                            readingOptions: JSONSerialization.ReadingOptions,
                                            completion: @escaping Completion<DataResponse<[Key: Value]>>) {
        makeRequest(success: { request in
            self.request = request.responseJSON(queue: queue,
                                                readingOptions: readingOptions,
                                                completionHandler: completion)
        }, failure: { error in
            completion(self.errorResponse(with: error))
        })
    }

    func responseString(queue: DispatchQueue? = nil,
                        encoding: String.Encoding?,
                        completion: @escaping Completion<DataResponse<String>>) {
        makeRequest(success: { request in
            self.request = request.responseString(queue: queue,
                                                  encoding: encoding,
                                                  completionHandler: completion)
        }, failure: { error in
            completion(self.errorResponse(with: error))
        })
    }

    func responseObject<Object: Decodable>(queue: DispatchQueue? = nil,
                                           decoder: JSONDecoder,
                                           completion: @escaping Completion<DataResponse<Object>>) {
        makeRequest(success: { request in
            self.request = request.responseObject(queue: queue,
                                                   decoder: decoder,
                                                   completionHandler: completion)
        }, failure: { error in
            completion(self.errorResponse(with: error))
        })
    }

    func cancel() {
        isCancelled = true
        request?.cancel()
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
            guard self.isCancelled else {
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
                              headers: httpHeaders,
                              encodingCompletion: encodingCompletion)
    }

    private func errorResponse<T>(with error: Error) -> DataResponse<T> {
        return DataResponse<T>(request: nil, response: nil, data: nil, result: .failure(error))
    }

    func addHeader(_ header: RequestHeader) {
        // TODO: find way to move to `NetworkRequest` protocol
        let headerIndexOrNil = additionalHeaders.firstIndex { existingHeader in
            return existingHeader.key == header.key
        }

        if let headerIndex = headerIndexOrNil {
            additionalHeaders.remove(at: headerIndex)
        }

        additionalHeaders.append(header)
    }
}
