//
// Created by Nikita Zatsepilov on 03/12/2018.
// Copyright (c) 2018 Ronas IT. All rights reserved.
//

import Alamofire

final class UploadRequest: Request {

    private let imageBodyParts: [ImageBodyPart]

    private var completion: Completion?
    private var sentRequest: DataRequest?

    init(session: Alamofire.Session, endpoint: UploadEndpoint) {
        imageBodyParts = endpoint.imageBodyParts
        super.init(session: session, endpoint: endpoint)
    }

    override func response(completion: @escaping Completion) {
        self.completion = completion
        sentRequest = nil
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

        let threshold = MultipartFormData.encodingMemoryThreshold
        sentRequest = session.upload(
            multipartFormData: multipartFormDataHandler,
            to: endpoint.url,
            usingThreshold: threshold,
            method: .post,
            headers: headers.httpHeaders
        ).validate()
        Logging.log(type: .debug, category: .request, "\(self) - Sending")
        sentRequest?.responseData { (response: AFDataResponse<Data>) in
            Logging.log(type: .debug, category: .request, "\(self) - Finished")
            self.completion?(self, response)
        }
    }

    @discardableResult
    override func cancel() -> Bool {
        guard let request = sentRequest else {
            Logging.log(type: .fault, category: .request, "\(self) - Couldn't cancel request: request hasn't started yet")
            return false
        }
        request.cancel()
        Logging.log(type: .debug, category: .request, "\(self) - Cancelling")
        sentRequest = nil
        return true
    }

    override func retry() -> Bool {
        // 1. Request hasn't started yet, because `completion` is nil
        guard let completion = completion else {
            Logging.log(type: .fault, category: .request, "\(self) - Couldn't retry request: request hasn't started yet")
            return false
        }
        Logging.log(type: .debug, category: .request, "\(self) - Retrying")
        response(completion: completion)
        return true
    }
}
