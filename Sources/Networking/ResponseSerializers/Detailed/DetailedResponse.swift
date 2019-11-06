//
//  Created by Nikita Zatsepilov on 06.11.2019
//  Copyright © 2019 Ronas IT. All rights reserved.
//

import Alamofire

public typealias DetailedEmptyResponse = DetailedResponse<Void>

public class DetailedResponse<Result> {

    typealias Headers = [AnyHashable: Any]

    let statusCode: Int
    let headers: Headers
    let result: Result

    init(statusCode: Int, headers: Headers, result: Result) {
        self.statusCode = statusCode
        self.headers = headers
        self.result = result
    }
}

extension DetailedEmptyResponse {

    convenience init(statusCode: Int, headers: Headers) {
        self.init(statusCode: statusCode, headers: headers, result: ())
    }

    convenience init(response: DetailedResponse<Data>) {
        self.init(statusCode: response.statusCode, headers: response.headers)
    }
}
