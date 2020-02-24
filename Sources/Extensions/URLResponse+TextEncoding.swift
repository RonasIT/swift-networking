//
//  Created by Nikita Zatsepilov on 05.02.2020
//  Copyright © 2020 Ronas IT. All rights reserved.
//

import Foundation
import CoreFoundation

extension URLResponse {

    var textEncoding: String.Encoding? {
        guard let encodingName = textEncodingName else {
            return nil
        }

        let encoding = CFStringConvertIANACharSetNameToEncoding(encodingName as CFString)
        return String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(encoding))
    }
}
