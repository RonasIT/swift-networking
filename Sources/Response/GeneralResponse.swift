//
// Created by Nikita Zatsepilov on 09/12/2018.
// Copyright (c) 2018 Ronas IT. All rights reserved.
//

import Alamofire

public final class GeneralResponse<T> {

    let request: RetryableRequest
    let dataResponse: DataResponse<T>

    init(request: RetryableRequest, dataResponse: DataResponse<T>) {
        self.request = request
        self.dataResponse = dataResponse
    }
}
