//
//  Created by Nikita Zatsepilov on 06.11.2019
//  Copyright © 2019 Ronas IT. All rights reserved.
//

import Alamofire

public final class DetailedResponse<Result> {

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
