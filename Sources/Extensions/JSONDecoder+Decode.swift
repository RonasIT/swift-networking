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
        } catch let decodingError as DecodingError {
            description += decodingError.description
            if let json = String(data: data, encoding: .utf8) {
                description += "\n📄 for JSON: \(json)"
            }
            throw CustomDecodingError(errorDescription: description)
        } catch {
            description += error.localizedDescription
            throw CustomDecodingError(errorDescription: description)
        }
    }
}

// MARK: -  Error

private struct CustomDecodingError: LocalizedError {
    let errorDescription: String
}
