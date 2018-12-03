//
//  Created by Dmitry Frishbuter on 27/09/2018
//  Copyright © 2018 Ronas IT. All rights reserved.
//

import Alamofire

public enum RequestAuth {
    case none
    case token(String)
}

public protocol ErrorHandler {
    func handle<T>(error: inout Error, for response: DataResponse<T>?, endpoint: Endpoint) -> Bool
}

public protocol BasicRequest: AnyObject {

    var endpoint: Endpoint { get }
    var auth: RequestAuth  { get set }
    var errorHandlers: [ErrorHandler] { get set }
}

public protocol Request: BasicRequest {

    typealias SuccessHandler<T> = (T) -> Void
    typealias FailureHandler = (Error) -> Void

    func responseString(successHandler: @escaping SuccessHandler<String>,
                        failureHandler: @escaping FailureHandler)

    func responseDecodableObject<Object: Decodable>(with decoder: JSONDecoder,
                                                    successHandler: @escaping SuccessHandler<Object>,
                                                    failureHandler: @escaping FailureHandler)

    func responseJSON(with readingOptions: JSONSerialization.ReadingOptions,
                      successHandler: @escaping SuccessHandler<Any>,
                      failureHandler: @escaping FailureHandler)

    func responseData(successHandler: @escaping SuccessHandler<Data>,
                      failureHandler: @escaping FailureHandler)

    func cancel()
}
