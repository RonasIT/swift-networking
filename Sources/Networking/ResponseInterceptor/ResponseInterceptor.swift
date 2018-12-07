//
// Created by Nikita Zatsepilov on 07/12/2018.
// Copyright (c) 2018 Ronas IT. All rights reserved.
//

import Foundation
import Alamofire

public final class ResponseCallback<T> {

    let success: Success<T>
    let failure: Failure

    init(success: @escaping Success<T>, failure: @escaping Failure) {
        self.success = success
        self.failure = failure
    }
}

protocol ResponseInterceptor: AnyObject {

    func interceptResponse<T>(of request: NetworkRequest,
                              response: DataResponse<T>,
                              endpoint: Endpoint,
                              responseCallback: ResponseCallback<T>) -> Bool
}
