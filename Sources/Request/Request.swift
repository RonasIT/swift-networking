//
//  Created by Dmitry Frishbuter on 27/09/2018
//  Copyright © 2018 Ronas IT. All rights reserved.
//

import Alamofire

public enum RequestAuthorization {
    case none
    case token(String)
}

public protocol Request: AnyObject {

    typealias Completion<T> = (T) -> Void

    var endpoint: Endpoint { get }
    var authorization: RequestAuthorization  { get }

    func cancel()
}

protocol NetworkRequest: Request {

    func responseData(queue: DispatchQueue?, completion: @escaping Completion<DataResponse<Data>>)

    func responseJSON(queue: DispatchQueue?,
                      readingOptions: JSONSerialization.ReadingOptions,
                      completion: @escaping Completion<DataResponse<Any>>)

    func responseObject<Object: Decodable>(queue: DispatchQueue?,
                                           decoder: JSONDecoder,
                                           completion: @escaping Completion<DataResponse<Object>>)

    func responseString(queue: DispatchQueue?,
                        encoding: String.Encoding?,
                        completion: @escaping Completion<DataResponse<String>>)
}
