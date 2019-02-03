//
// Created by Nikita Zatsepilov on 03/12/2018.
// Copyright (c) 2018 Ronas IT. All rights reserved.
//

import Alamofire

final class UploadRequest<Result>: Request<Result> {

    private let imageBodyParts: [ImageBodyPart]

    private var isCreatingMultipartFormData: Bool = false
    private var isCancelled: Bool = false

    private var completion: Completion?
    private var sentRequest: DataRequest?

    init(sessionManager: SessionManager,
         endpoint: UploadEndpoint,
         responseSerializer: DataResponseSerializer<Result>) {
        imageBodyParts = endpoint.imageBodyParts
        super.init(sessionManager: sessionManager, endpoint: endpoint, responseSerializer: responseSerializer)
    }

    override func response(completion: @escaping (DataResponse<Result>) -> Void) {
        self.completion = completion
        sentRequest = nil
        isCancelled = false
        isCreatingMultipartFormData = true
        let multipartFormDataHandler = { (multipartFormData: MultipartFormData) in
            guard !self.isCancelled else {
                self.failAsCancelled(with: completion)
                return
            }
            multipartFormData.appendImageBodyParts(self.imageBodyParts)
            if let parameters = self.endpoint.parameters {
                multipartFormData.appendParametersBodyParts(parameters)
            }
        }
        let encodingCompletion = { (encodingResult: SessionManager.MultipartFormDataEncodingResult) in
            self.isCreatingMultipartFormData = false
            guard !self.isCancelled else {
                self.failAsCancelled(with: completion)
                return
            }
            switch encodingResult {
            case .success(let request, _, _):
                self.sentRequest = request
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

    @discardableResult
    override func cancel() -> Bool {
        // 1. Request is not sent, but we are waiting multipart-form data
        if isCreatingMultipartFormData, !isCancelled {
            isCancelled = true
            return true
        }

        // 2. Try to cancel sent request
        if let request = sentRequest {
            request.cancel()
            sentRequest = nil
            return true
        }

        // 3. Request hasn't started yet
        return false
    }

    override func retry() -> Bool {
        // 1. Request hasn't started yet, because `completion` is nil
        guard let completion = completion else {
            return false
        }

        isCancelled = false

        // 2. Request will be sent, once multipart-form data will be created
        // No need to start request again
        guard !isCreatingMultipartFormData else {
            return true
        }

        // 3. Request has been already sent
        response(completion: completion)
        return true
    }

    private func failAsCancelled(with completion: Completion) {
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled)
        completion(DataResponse(request: nil, response: nil, data: nil, result: .failure(error)))
    }
}
