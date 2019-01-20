//
//  Created by Dmitry Frishbuter on 27/09/2018
//  Copyright © 2018 Ronas IT. All rights reserved.
//

import Foundation

#warning("Remove EndpointError?")

public protocol EndpointError {
    func error(for code: String, description: String?) -> Error?
}

public extension EndpointError {
    func error(for code: String, description: String?) -> Error? {
        return nil
    }
}
