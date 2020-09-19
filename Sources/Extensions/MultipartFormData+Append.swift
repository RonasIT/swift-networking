//
//  Created by Dmitry Frishbuter on 27/09/2018
//  Copyright © 2018 Ronas IT. All rights reserved.
//

import Foundation
import Alamofire

extension Alamofire.MultipartFormData {

    func appendImageBodyParts(_ bodyParts: [ImageBodyPart]) {
        for bodyPart in bodyParts {
            append(bodyPart.imageData, withName: bodyPart.name, fileName: bodyPart.fileName, mimeType: bodyPart.mimeType)
        }
    }

    func appendParametersBodyParts(_ parameters: Parameters) {
        for (key, value) in parameters {
            switch value {
            case let intValue as Int:
                append(String(intValue).data(using: .utf8)!, withName: key)
            case let uintValue as UInt:
                append(String(uintValue).data(using: .utf8)!, withName: key)
            case let stringValue as String:
                append(stringValue.data(using: .utf8)!, withName: key)
            case let data as Data:
                append(data, withName: key)
            case let url as URL:
                append(url, withName: key)
            default: break
            }
        }
    }
}
