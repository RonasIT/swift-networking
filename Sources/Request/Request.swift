//
//  Created by Dmitry Frishbuter on 27/09/2018
//  Copyright © 2018 Ronas IT. All rights reserved.
//

import Alamofire

public final class Request<ResponseType>: BaseRequest<ResponseType> {

    typealias EncodingCompletionHandler = (SessionManager.MultipartFormDataEncodingResult) -> Void
    private let request: DataRequest

    override init<U: ResponseBuilder>(endpoint: Endpoint,
                                      responseBuilder: U,
                                      sessionManager: SessionManager = SessionManager.default) where U.Response == ResponseType {
        request = sessionManager.request(endpoint.url,
                                         method: endpoint.method,
                                         parameters: endpoint.parameters,
                                         encoding: endpoint.parameterEncoding,
                                         headers: endpoint.headers.httpHeaders).validate()
        super.init(endpoint: endpoint, responseBuilder: responseBuilder, sessionManager: sessionManager)
    }

    func responseJSON(_ handler: @escaping CompletionHandler<ResponseType>) {
        completionHandler = handler
        request.responseJSON { (response: DataResponse<Any>) in
            switch response.result {
            case .failure(let error):
                self.handleError(error, forResponse: response)
            case .success(let json):
                self.handleResponseData(json)
            }
        }
    }

    func responseData(_ handler: @escaping CompletionHandler<ResponseType>) {
        completionHandler = handler
        request.responseData { (response: DataResponse<Data>) in
            switch response.result {
            case .failure(let error):
                self.handleError(error, forResponse: response)
            case .success(let data):
                self.handleResponseData(data)
            }
        }
    }

    func cancel() {
        request.cancel()
    }
}
