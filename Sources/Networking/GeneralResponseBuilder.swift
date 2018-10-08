//
//  Created by Dmitry Frishbuter on 27/09/2018
//  Copyright © 2018 Ronas IT. All rights reserved.
//

import Foundation

final class GeneralResponseBuilder: ResponseBuilder {

    typealias Response = GeneralResponse

    func response(from data: Any) -> GeneralResponse {
        if let json = data as? [String: Any] {
            return generalResponse(from: json)
        }
        else if let json = data as? [Any] {
            return generalResponse(from: json)
        }
        fatalError("Wrong response data \(data)")
    }

    private func generalResponse(from data: Any) -> GeneralResponse {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: data)
            return GeneralResponse(jsonData: jsonData)
        }
        catch {
            fatalError("Wrong response data \(data)")
        }
    }
}
