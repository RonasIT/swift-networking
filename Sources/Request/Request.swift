//
//  Created by Dmitry Frishbuter on 27/09/2018
//  Copyright © 2018 Ronas IT. All rights reserved.
//

import Alamofire

public enum RequestAuthorization {
    case none
    case token(String)
}

public protocol BasicRequest {

    typealias Success<T> = (T) -> Void
    typealias Failure = (Error) -> Void

    var endpoint: Endpoint { get }
    var authorization: RequestAuthorization  { get }
}

public protocol Request: AnyObject, BasicRequest {

    func responseString(success: @escaping Success<String>,
                        failure: @escaping Failure)

    func responseDecodableObject<Object: Decodable>(with decoder: JSONDecoder,
                                                    success: @escaping Success<Object>,
                                                    failure: @escaping Failure)

    func responseJSON(with readingOptions: JSONSerialization.ReadingOptions,
                      success: @escaping Success<[AnyHashable: Any]>,
                      failure: @escaping Failure)

    func responseData(success: @escaping Success<Data>,
                      failure: @escaping Failure)

    func cancel()
}
