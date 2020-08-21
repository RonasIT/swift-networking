//
//  Created by Dmitry Frishbuter on 21.08.2020
//  Copyright © 2020 Ronas IT. All rights reserved.
//

import Alamofire

extension HTTPHeaders: Equatable {

    public static func == (lhs: HTTPHeaders, rhs: HTTPHeaders) -> Bool {
        return lhs.dictionary == rhs.dictionary
    }
}
