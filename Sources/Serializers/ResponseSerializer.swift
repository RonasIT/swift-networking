//
// Created by Nikita Zatsepilov on 2019-01-27.
// Copyright (c) 2019 Ronas IT. All rights reserved.
//

public protocol ResponseSerializer {

    associatedtype Response

    func serialize(_ response: DataResponse) throws -> Response
}
