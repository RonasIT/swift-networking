//
//  Created by Nikita Zatsepilov on 06.02.2020
//  Copyright © 2020 Ronas IT. All rights reserved.
//

public final class AnyResponseSerializer<Response>: ResponseSerializer {

    public typealias Serialization = (DataResponse) throws -> Response

    private let serialization: Serialization

    init(serialization: @escaping Serialization) {
        self.serialization = serialization
    }

    public func serialize(_ response: DataResponse) throws -> Response {
        return try serialization(response)
    }
}
