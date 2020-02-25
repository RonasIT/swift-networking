//
// Created by Nikita Zatsepilov on 2019-01-23.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

public protocol EndpointError {
    func error(forStatusCode statusCode: Int) -> Error?
    func error(for urlErrorCode: URLError.Code) -> Error?
}
