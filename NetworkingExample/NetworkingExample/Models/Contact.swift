//
//  Created by Dmitry Frishbuter on 09/10/2018.
//  Copyright © 2018 Ronas IT. All rights reserved.
//

import Foundation

final class Contact: Codable {
    let id: String
    let name: String
    let url: URL

    init(id: String, name: String, url: URL) {
        self.id = id
        self.name = name
        self.url = url
    }
}
