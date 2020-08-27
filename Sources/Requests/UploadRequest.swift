//
// Created by Nikita Zatsepilov on 03/12/2018.
// Copyright (c) 2018 Ronas IT. All rights reserved.
//

import Alamofire

final class UploadRequest: Request {
    private let imageBodyParts: [ImageBodyPart]

    public var progress: Progress?
    private var completion: Completion?
    private var sentRequest: DataRequest?

    init(session: Alamofire.Session, endpoint: UploadEndpoint) {
        imageBodyParts = endpoint.imageBodyParts
        super.init(session: session, endpoint: endpoint)
    }

    override func response(completion: @escaping Completion) {
        self.completion = completion
        sentRequest = nil
        let multipartFormDataComposer = { (multipartFormData: MultipartFormData) in
            // Warning: this handler uses concurrent background queue
            multipartFormData.appendImageBodyParts(self.imageBodyParts)
            if let parameters = self.endpoint.parameters {
                multipartFormData.appendParametersBodyParts(parameters)
            }
        }

        let threshold = MultipartFormData.encodingMemoryThreshold
        sentRequest = session.upload(
            multipartFormData: multipartFormDataComposer,
            to: endpoint.url,
            usingThreshold: threshold,
            method: .post,
            headers: headers.httpHeaders
            ).validate()

        if let progress = self.progress {
            sentRequest?.uploadProgress(closure: progress)
            self.progress = nil
        }

        sentRequest?.responseData { (response: AFDataResponse<Data>) in
            self.completion?(self, response)
        }
    }

    @discardableResult
    override func cancel() -> Bool {
        guard let request = sentRequest else {
            return false
        }
        request.cancel()
        sentRequest = nil
        return true
    }

    override func retry() -> Bool {
        // 1. Request hasn't started yet, because `completion` is nil
        guard let completion = completion else {
            return false
        }
        response(completion: completion)
        return true
    }
}
