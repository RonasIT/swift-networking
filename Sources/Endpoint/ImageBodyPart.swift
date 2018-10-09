//
//  Created by Dmitry Frishbuter on 27/09/2018
//  Copyright © 2018 Ronas IT. All rights reserved.
//

import UIKit.UIImage

public struct ImageBodyPart {
    var imageData: Data
    var name: String
    var fileName: String
    var mimeType: String

    public init(imageData: Data, name: String = "photo", fileName: String = "photo.jpg", mimeType: String = "image/jpg") {
        self.imageData = imageData
        self.name = name
        self.fileName = fileName
        self.mimeType = mimeType
    }
}
