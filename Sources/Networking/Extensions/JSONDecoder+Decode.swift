//
//  Created by Dmitry Frishbuter on 27/09/2018
//  Copyright © 2018 Ronas IT. All rights reserved.
//

import Foundation

public extension JSONDecoder {

    func decode<T: Decodable>(from data: Data) throws -> T {
        var description = "❌ Decoding error:\n"
        do {
            return try decode(T.self, from: data)
        }
        catch let decodingError as DecodingError {
            description += decodingError.description
            if let json = String(data: data, encoding: .utf8) {
                description += "\n📄 for JSON: \(json)"
            }
            throw Error.with(description)
        }
        catch {
            description += error.localizedDescription
            throw Error.with(description)
        }
    }
}

// MARK: - Error

private enum Error: Swift.Error {
    case with(String)
}

extension Error: LocalizedError {
    var errorDescription: String? {
        switch self {
        case let .with(description):
            return description
        }
    }
}
