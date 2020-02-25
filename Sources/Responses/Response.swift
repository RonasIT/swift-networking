//
//  Created by Nikita Zatsepilov on 06.11.2019
//  Copyright © 2019 Ronas IT. All rights reserved.
//

import Alamofire

public typealias DataResponse = Response<Data>
public typealias DecodableResponse<Result: Decodable> = Response<Result>
public typealias JSONResponse = Response<[String: Any]>
public typealias StringResponse = Response<String>
public typealias EmptyResponse = Response<Void>

public final class Response<Result>: ResponseType {

    public let result: Result
    public let httpResponse: HTTPURLResponse

    init(result: Result, httpResponse: HTTPURLResponse) {
        self.result = result
        self.httpResponse = httpResponse
    }
}
