//
//  Created by Dmitry Frishbuter on 21.08.2020
//  Copyright © 2020 Ronas IT. All rights reserved.
//

struct AnyError: Error {
    let base: Error

    init<Error: Swift.Error>(_ base: Error) {
        self.base = base
    }
}
