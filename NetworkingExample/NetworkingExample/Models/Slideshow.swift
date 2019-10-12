//
//  Created by Dmitry Frishbuter on 10/10/2018.
//  Copyright © 2018 Ronas IT. All rights reserved.
//

import Foundation

final class Slideshow: Codable {
    let author: String
    let date: String
    let slides: [Slide]
    let title: String
}

final class Slide: Codable {
    let title: String
    let type: String
    let items: [String]?
}
