//
//  Created by Dmitry Frishbuter on 27/09/2018
//  Copyright © 2018 Ronas IT. All rights reserved.
//

import Alamofire
import UIKit.UIImage

public final class UploadRequest<ResponseType>: BaseRequest<ResponseType> {

    public typealias CompletionHandler<T> = (T?, Error?) -> Void
    public typealias EncodingCompletionHandler = (Error?) -> Void
    public typealias RequestHandler = (DataRequest) -> Void

    private var request: DataRequest? {
        didSet {
            if let request = request {
                self.deferredRequestHandler?(request)
            }
        }
    }

    private var deferredRequestHandler: RequestHandler?
    private var isCancelled: Bool = false

    init<U: ResponseBuilder>(endpoint: Endpoint,
                             imageBodyParts: [ImageBodyPart],
                             responseBuilder: U,
                             sessionManager: SessionManager = SessionManager.default,
                             encodingCompletion: @escaping EncodingCompletionHandler) where U.Response == ResponseType {
        super.init(endpoint: endpoint, responseBuilder: responseBuilder, sessionManager: sessionManager)

        sessionManager.upload(multipartFormData: { multipartFormData in
            multipartFormData.appendImageBodyParts(imageBodyParts)
            if let parameters = endpoint.parameters {
                multipartFormData.appendParametersBodyParts(parameters)
            }
        }, usingThreshold: SessionManager.multipartFormDataEncodingMemoryThreshold,
           to: endpoint.url,
           method: .post,
           headers: endpoint.headers.httpHeaders,
           encodingCompletion: { [weak self] encodingResult in
            guard let `self` = self, !self.isCancelled else {
                return
            }
            switch encodingResult {
            case .success(let request, _, _):
                self.request = request
                request.validate()
                encodingCompletion(nil)
            case .failure(let error):
                encodingCompletion(error)
            }
        })
    }

    func responseJSON(_ handler: @escaping CompletionHandler<ResponseType>) {
        completionHandler = handler
        let requestHandler: RequestHandler = { request in
            request.responseJSON { response in
                switch response.result {
                case .failure(let error):
                    self.handleError(error, forResponse: response)
                case .success(let json):
                    self.handleResponseData(json)
                }
            }
        }
        guard let request = request else {
            deferredRequestHandler = requestHandler
            return
        }
        requestHandler(request)
    }

    func responseData(_ handler: @escaping CompletionHandler<ResponseType>) {
        completionHandler = handler
        let requestHandler: RequestHandler = { request in
            request.responseData { response in
                switch response.result {
                case .failure(let error):
                    self.handleError(error, forResponse: response)
                case .success(let data):
                    self.handleResponseData(data)
                }
            }
        }
        guard let request = request else {
            deferredRequestHandler = requestHandler
            return
        }
        requestHandler(request)
    }

    func cancel() {
        guard let request = request else {
            isCancelled = true
            return
        }
        request.cancel()
    }
}
