//
// Created by Nikita Zatsepilov on 03/12/2018.
// Copyright (c) 2018 Ronas IT. All rights reserved.
//

import Alamofire

final class UploadRequest: Request {

    private typealias MultipartFormDataEncodingResult = SessionManager.MultipartFormDataEncodingResult

    private let imageBodyParts: [ImageBodyPart]

    private var isCreatingMultipartFormData: Bool = false
    private var isCancelled: Bool = false

    private var completion: Completion?
    private var sentRequest: DataRequest?

    init(sessionManager: SessionManager, endpoint: UploadEndpoint) {
        imageBodyParts = endpoint.imageBodyParts
        super.init(sessionManager: sessionManager, endpoint: endpoint)
    }

    override func response(completion: @escaping Completion) {
        self.completion = completion
        sentRequest = nil
        isCancelled = false
        isCreatingMultipartFormData = true
        let multipartFormDataHandler = { (multipartFormData: MultipartFormData) in
            // Warning: this handler uses concurrent background queue
            multipartFormData.appendImageBodyParts(self.imageBodyParts)
            if let parameters = self.endpoint.parameters {
                multipartFormData.appendParametersBodyParts(parameters)
            }

            Logging.log(
                type: .debug,
                category: .request,
                "\(self) - Created multipart-form data with \(multipartFormData.contentLength) bytes"
            )
        }

        let threshold = SessionManager.multipartFormDataEncodingMemoryThreshold
        sessionManager.upload(
            multipartFormData: multipartFormDataHandler,
            usingThreshold: threshold,
            to: endpoint.url,
            method: .post,
            headers: headers.httpHeaders,
            encodingCompletion: encodingCompletion(withRequestCompletion: completion)
        )
    }

    private func encodingCompletion(withRequestCompletion requestCompletion: @escaping Completion) -> (MultipartFormDataEncodingResult) -> Void {
        let encodingCompletion = { (encodingResult: MultipartFormDataEncodingResult) in
            switch encodingResult {
            case .failure(let error):
                Logging.log(
                    type: .fault,
                    category: .request,
                    "\(self) - Failed multipart-form data encoding with error: \(error)"
                )
            case .success:
                Logging.log(
                    type: .debug,
                    category: .request,
                    "\(self) - Completed multipart-form data encoding"
                )
            }

            self.isCreatingMultipartFormData = false
            guard !self.isCancelled else {
                self.failAsCancelled(with: requestCompletion)
                return
            }
            switch encodingResult {
            case .success(let request, _, _):
                self.sentRequest = request
                request.validate()
                Logging.log(type: .debug, category: .request, "\(self) - Sending")
                request.responseData { response in
                    if self.isCancelled {
                        self.failAsCancelled(with: requestCompletion)
                    } else {
                        requestCompletion(self, response)
                    }
                }
            case .failure(let error):
                requestCompletion(self, Alamofire.DataResponse(request: nil, response: nil, data: nil, result: .failure(error)))
            }
        }
        return encodingCompletion
    }

    @discardableResult
    override func cancel() -> Bool {
        // 1. Request is not sent, but we are waiting multipart-form data
        if isCreatingMultipartFormData, !isCancelled {
            Logging.log(type: .debug, category: .request, "\(self) - Will be cancelled after multipart-form data creation")
            isCancelled = true
            return true
        }

        // 2. Try to cancel sent request
        if let request = sentRequest {
            Logging.log(type: .debug, category: .request, "\(self) - Cancelling")
            request.cancel()
            sentRequest = nil
            return true
        }

        // 3. Request hasn't started yet
        Logging.log(type: .fault, category: .request, "\(self) - Couldn't cancel request: request hasn't started yet")
        return false
    }

    override func retry() -> Bool {
        // 1. Request hasn't started yet, because `completion` is nil
        guard let completion = completion else {
            Logging.log(type: .fault, category: .request, "\(self) - Couldn't retry request: request hasn't started yet")
            return false
        }

        isCancelled = false

        // 2. Request will be sent, once multipart-form data will be created
        // No need to start request again
        guard !isCreatingMultipartFormData else {
            Logging.log(type: .debug, category: .request, "\(self) - Will be retried after multipart-form data creation")
            return true
        }

        // 3. Request has been already sent
        Logging.log(type: .debug, category: .request, "\(self) - Retrying")
        response(completion: completion)
        return true
    }

    private func failAsCancelled(with completion: Completion) {
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled)
        completion(self, Response(request: nil, response: nil, data: nil, result: .failure(error)))
    }
}
