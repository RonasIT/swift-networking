//
//  Created by Dmitry Frishbuter on 27/09/2018
//  Copyright © 2018 Ronas IT. All rights reserved.
//

import Networking

final class ApiService: NetworkService, ApiServiceProtocol {

    @discardableResult
    func fetchContact(success: @escaping (Contact) -> Void, failure: Failure?) -> Request<GeneralResponse>? {
        let contact = Contact(id: "235", name: "Michael", url: URL(string: "https://www.michaelexample.com")!)
        return request(for: AnythingEndpoint.fetchData(contact), success: { (result: AnythingResponse) in
            success(result.args)
        }, failure: { error in
            failure?(error)
        })
    }

    @discardableResult
    func postContact(_ contact: Contact, success: @escaping (Contact) -> Void, failure: Failure?) -> Request<GeneralResponse>? {
        return request(for: AnythingEndpoint.fetchData(contact), success: { (result: AnythingResponse) in
            success(result.args)
        }, failure: { error in
            failure?(error)
        })
    }
}

private final class AnythingResponse: Decodable {
    let args: Contact
}
