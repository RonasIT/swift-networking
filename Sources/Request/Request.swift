//
//  Created by Dmitry Frishbuter on 27/09/2018
//  Copyright © 2018 Ronas IT. All rights reserved.
//

import Alamofire

public protocol Request: AnyObject {

    var endpoint: Endpoint { get }

    func cancel()
}

protocol NetworkRequest: Request {

    // TODO: move headers logic to separated protocol

    typealias Completion<T> = (T) -> Void

    var additionalHeaders: [RequestHeader] { get }
    var httpHeaders: HTTPHeaders { get }

    func responseData(queue: DispatchQueue?, completion: @escaping Completion<DataResponse<Data>>)

    func responseJSON<Key: Hashable, Value: Any>(queue: DispatchQueue?,
                                                 readingOptions: JSONSerialization.ReadingOptions,
                                                 completion: @escaping Completion<DataResponse<[Key: Value]>>)

    func responseObject<Object: Decodable>(queue: DispatchQueue?,
                                           decoder: JSONDecoder,
                                           completion: @escaping Completion<DataResponse<Object>>)

    func responseString(queue: DispatchQueue?,
                        encoding: String.Encoding?,
                        completion: @escaping Completion<DataResponse<String>>)

    func addHeader(_ header: RequestHeader)
}

extension NetworkRequest {

    var httpHeaders: HTTPHeaders {
        var headers = endpoint.headers.httpHeaders
        // Merging with additional headers
        // Additional headers will override headers from endpoint
        headers.merge(additionalHeaders.httpHeaders) { $1 }
        return headers
    }
}
