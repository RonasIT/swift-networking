//
//  Created by Dmitry Frishbuter on 27/09/2018
//  Copyright © 2018 Ronas IT. All rights reserved.
//

import Foundation

public enum GeneralRequestError: Error {
    case noInternetConnection
    case timedOut
    case noAuth
    case notFound
    case cancelled
}
