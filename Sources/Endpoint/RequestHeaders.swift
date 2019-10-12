//
//  Created by Nikita Zatsepilov on 15/08/2019
//  Copyright © 2019 Ronas IT. All rights reserved.
//

import UIKit.UIDevice

public enum RequestHeaders: RequestHeader {

    case authorization(String)
    case contentType(String)
    case accept(String)
    case userAgent(osVersion: String, appVersion: String)
    case dpi(scale: CGFloat)
    case custom(key: String, value: String)

    public var key: String {
        switch self {
        case .authorization:
            return "Authorization"
        case .contentType:
            return "Content-Type"
        case .accept:
            return "Accept"
        case .userAgent:
            return "User-Agent"
        case .dpi:
            return "dpi"
        case let .custom(key, _):
            return key
        }
    }

    public var value: String {
        switch self {
        case let .authorization(token):
            return "Bearer \(token)"
        case let .contentType(type):
            return type
        case let .accept(value):
            return value
        case let .userAgent(osVersion, appVersion):
            return "iOS \(osVersion) version \(appVersion)"
        case let .dpi(scale):
            return "@\(Int(scale))x"
        case let .custom(_, value):
            return value
        }
    }
}
