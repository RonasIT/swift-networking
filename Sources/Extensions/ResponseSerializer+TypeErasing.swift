//
//  Created by Nikita Zatsepilov on 06.02.2020
//  Copyright © 2020 Ronas IT. All rights reserved.
//

extension ResponseSerializer {

    func typeErased() -> AnyResponseSerializer<Response> {
        return AnyResponseSerializer { try self.serialize($0) }
    }
}
