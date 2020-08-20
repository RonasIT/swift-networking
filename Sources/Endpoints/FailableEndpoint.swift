//
//  Created by Dmitry Frishbuter on 20.08.2020
//  Copyright © 2020 Ronas IT. All rights reserved.
//

public protocol FailableEndpoint {
    func error(for statusCode: StatusCode) -> Error?
    func error(for urlErrorCode: URLError.Code) -> Error?
}
