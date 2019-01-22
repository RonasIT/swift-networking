//
//  Created by Dmitry Frishbuter on 27/09/2018
//  Copyright © 2018 Ronas IT. All rights reserved.
//

import Alamofire

public protocol UploadEndpoint: Endpoint {
    var imageBodyParts: [ImageBodyPart] { get }
}

public extension UploadEndpoint {

    var method: HTTPMethod {
        return .post
    }

    var imageBodyParts: [ImageBodyPart] {
        return []
    }
}
