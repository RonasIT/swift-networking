//
//  Created by Dmitry Frishbuter on 27/09/2018
//  Copyright © 2018 Ronas IT. All rights reserved.
//

public extension URL {
    static func + (lhs: URL, rhs: String) -> URL {
        return lhs.appendingPathComponent(rhs)
    }
}
