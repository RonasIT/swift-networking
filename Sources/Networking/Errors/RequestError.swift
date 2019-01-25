//
// Created by Nikita Zatsepilov on 2019-01-17.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

import Alamofire

public struct RequestError<T> {

    public let endpoint: Endpoint
    public let error: Error
    public let response: DataResponse<T>
}
