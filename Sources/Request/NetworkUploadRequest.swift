//
// Created by Nikita Zatsepilov on 03/12/2018.
// Copyright (c) 2018 Ronas IT. All rights reserved.
//

import Alamofire

final class NetworkUploadRequest: Request, Cancellable {

    public let id: String
    public let endpoint: Endpoint

    private let sessionManager: SessionManager
    private let imageBodyParts: [ImageBodyPart]
    private var headers: [RequestHeader]

    private var isCancelled: Bool = false
    private var cancellation: (() -> Void)?
    private var sending: (() -> Void)?

    init(sessionManager: SessionManager = SessionManager.default, endpoint: UploadEndpoint) {
        self.endpoint = endpoint
        self.sessionManager = sessionManager
        id = UUID().uuidString
        imageBodyParts = endpoint.imageBodyParts
        headers = endpoint.headers
    }

    deinit {
        print("\(self) \(#function)")
    }

    func response<Serializer: ResponseSerializer>(queue: DispatchQueue? = nil,
                                                  responseSerializer: Serializer,
                                                  completion: @escaping Completion<Serializer.SerializedObject>) {
        sending = { [unowned self] in
            self.start(sending: { request in
                guard !self.isCancelled else {
                    let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled)
                    completion(DataResponse(request: nil, response: nil, data: nil, result: .failure(error)))
                    return
                }
                self.cancellation = {
                    request.cancel()
                }
                request.response(queue: queue, responseSerializer: responseSerializer, completionHandler: completion)
            }, failure: { error in
                completion(DataResponse(request: nil, response: nil, data: nil, result: .failure(error)))
            })
        }
        sending?()
    }

    func cancel() {
        cancellation?()
        isCancelled = true
        sending = nil
    }

    func retry() {
        isCancelled = false
        sending?()
    }

    func append(_ header: RequestHeader) {
        let indexOrNil = headers.firstIndex { $0.key == header.key }
        if let index = indexOrNil {
            headers.remove(at: index)
        }
        headers.append(header)
    }

    // MARK: - Private

    private func start(sending: @escaping (DataRequest) -> Void, failure: @escaping (Error) -> Void) {
        isCancelled = false
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
                sending(request)
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
}
