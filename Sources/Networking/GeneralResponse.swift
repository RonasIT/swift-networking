//
//  Created by Dmitry Frishbuter on 27/09/2018
//  Copyright © 2018 Ronas IT. All rights reserved.
//

import Foundation

public final class GeneralResponse {
    public let jsonData: Data

    public init(jsonData: Data) {
        self.jsonData = jsonData
    }
}
