//
//  Created by Dmitry Frishbuter on 27/09/2018
//  Copyright © 2018 Ronas IT. All rights reserved.
//

import Networking

final class ApiService: NetworkService, ApiServiceProtocol {

    init(sessionService: SessionServiceProtocol) {
        let requestAdapters = [TokenRequestAdapter(sessionService: sessionService)]
        super.init(requestAdapters: requestAdapters)
    }

    @discardableResult
    func fetchSlideshow(success: @escaping (Slideshow) -> Void, failure: Failure?) -> Request? {
        return request(endpoint: AnythingEndpoint.fetchSlideshow, success: { (result: SlideshowResponse) in
            success(result.slideshow)
        }, failure: { error in
            failure?(error)
        })
    }

    @discardableResult
    func postContact(_ contact: Contact, success: @escaping (Contact) -> Void, failure: Failure?) -> Request? {

        return request(endpoint: AnythingEndpoint.postContact(contact), success: { (result: ContactResponse) in
            success(result.form)
        }, failure: { error in
            failure?(error)
        })
    }
}

private final class SlideshowResponse: Decodable {
    let slideshow: Slideshow
}

private final class ContactResponse: Decodable {
    let form: Contact
}
