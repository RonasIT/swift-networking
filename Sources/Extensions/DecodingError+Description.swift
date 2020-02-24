//
//  Created by Dmitry Frishbuter on 27/09/2018
//  Copyright © 2018 Ronas IT. All rights reserved.
//

import Foundation

extension DecodingError: CustomStringConvertible {

    public var errorDescription: String? {
        return description
    }

    public var description: String {
        var description = ""
        switch self {
        case .dataCorrupted(let context):
            description += context.debugDescription
        case .keyNotFound(_, let context):
            description += context.debugDescription
            if let codingKey = context.codingPath.last {
                description += "Value for \(codingKey.stringValue.uppercased()) was not found."
            }
        case .typeMismatch(_, let context):
            description += context.debugDescription
            if let codingKey = context.codingPath.last {
                description.removeLast()
                description += " for field " + "\(codingKey.stringValue.uppercased())" + "."
            }
        case .valueNotFound(_, let context):
            description += context.debugDescription
            if let codingKey = context.codingPath.last {
                description += "Value for field " + "\(codingKey.stringValue.uppercased())" + " is nil."
            }
        @unknown default:
            break
        }
        return description
    }
}
