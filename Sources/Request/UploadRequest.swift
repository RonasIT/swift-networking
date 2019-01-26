//
// Created by Nikita Zatsepilov on 03/12/2018.
// Copyright (c) 2018 Ronas IT. All rights reserved.
//

import Alamofire

final class UploadRequest<Result>: Request<Result> {

    private let imageBodyParts: [ImageBodyPart]

    private var isCancelled: Bool = false

    private var completion: Completion?
    private var request: DataRequest?

    init(sessionManager: SessionManager,
         endpoint: UploadEndpoint,
         responseSerializer: DataResponseSerializer<Result>) {
        imageBodyParts = endpoint.imageBodyParts
        super.init(sessionManager: sessionManager, endpoint: endpoint, responseSerializer: responseSerializer)
    }

    override func cancel() {
        isCancelled = true
        request?.cancel()
        request = nil
    }

    override func response(completion: @escaping (DataResponse<Result>) -> Void) {
        self.completion = completion
        let multipartFormDataHandler = { (multipartFormData: MultipartFormData) in
            guard !self.isCancelled else {
                self.failAsCancelled()
                return
            }
            multipartFormData.appendImageBodyParts(self.imageBodyParts)
            if let parameters = self.endpoint.parameters {
                multipartFormData.appendParametersBodyParts(parameters)
            }
        }
        let encodingCompletion = { (encodingResult: SessionManager.MultipartFormDataEncodingResult) in
            guard !self.isCancelled else {
                self.failAsCancelled()
                return
            }
            switch encodingResult {
            case .success(let request, _, _):
                request.validate()
                request.response(responseSerializer: self.responseSerializer, completionHandler: completion)
            case .failure(let error):
                completion(DataResponse(request: nil, response: nil, data: nil, result: .failure(error)))
            }
        }
        sessionManager.upload(multipartFormData: multipartFormDataHandler,
                              usingThreshold: SessionManager.multipartFormDataEncodingMemoryThreshold,
                              to: endpoint.url,
                              method: .post,
                              headers: headers.httpHeaders,
                              encodingCompletion: encodingCompletion)
    }

    private func failAsCancelled() {
        guard let completion = completion else {
            return
        }
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled)
        completion(DataResponse(request: nil, response: nil, data: nil, result: .failure(error)))
        self.completion = nil
    }
}
