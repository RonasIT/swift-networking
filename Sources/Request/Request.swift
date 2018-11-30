//
//  Created by Dmitry Frishbuter on 27/09/2018
//  Copyright © 2018 Ronas IT. All rights reserved.
//

import Alamofire

public typealias SuccessHandler<T> = (T) -> Void
public typealias FailureHandler = (Error) -> Void

public protocol Request: AnyObject {

    var endpoint: Endpoint { get }

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
}

public protocol ErrorHandler {
    func handle<T>(error: inout Error, for response: DataResponse<T>?, endpoint: Endpoint) -> Bool
}
