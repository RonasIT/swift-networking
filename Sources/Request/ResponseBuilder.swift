//
//  Created by Dmitry Frishbuter on 27/09/2018
//  Copyright © 2018 Ronas IT. All rights reserved.
//

import Foundation

protocol ResponseBuilder: class {
    associatedtype Response
    func response(from data: Any) -> Response
}

// MARK: - Type erasure

final class AnyResponseBuilder<T> {
    private let _buildResponse: (Any) -> T

    init<U: ResponseBuilder>(_ builder: U) where U.Response == T {
        _buildResponse = { data in
            return builder.response(from: data)
        }
    }

    func buildResponse(from data: Any) -> T {
        return _buildResponse(data)
    }
}
