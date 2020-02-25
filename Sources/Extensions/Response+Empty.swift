//
//  Created by Nikita Zatsepilov on 06.02.2020
//  Copyright © 2020 Ronas IT. All rights reserved.
//

extension Response {

    var empty: EmptyResponse {
        return EmptyResponse(result: (), httpResponse: httpResponse)
    }
}
