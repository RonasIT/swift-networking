//
//  Created by Dmitry Frishbuter on 21.08.2020
//  Copyright © 2020 Ronas IT. All rights reserved.
//

public enum AuthorizationType {
    /// The `"Basic"` token type.
    case basic
    /// The `"Bearer"` token type.
    case bearer
    /// Custom authorization token type.
    case custom(String)
    /// Used when the authorization is not required.
    case none

    public var rawValue: String {
        switch self {
        case .basic:
            return "Basic"
        case .bearer:
            return "Bearer"
        case .custom(let customValue):
            return customValue
        case .none:
            return ""
        }
    }
}

// MARK: -  Equatable

extension AuthorizationType: Equatable {

    public static func == (lhs: AuthorizationType, rhs: AuthorizationType) -> Bool {
        switch (lhs, rhs) {
        case (.basic, .basic):
            return true
        case (.bearer, .bearer):
            return true
        case (.custom(let lhsType), .custom(let rhsType)):
            return lhsType == rhsType
        case (.none, .none):
            return true
        default:
            return false
        }
    }
}
