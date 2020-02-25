//
//  Created by Dmitry Frishbuter on 27/09/2018
//  Copyright © 2018 Ronas IT. All rights reserved.
//

import Networking

final class ApiService: NetworkService, ApiServiceProtocol {

    @discardableResult
    func fetchSlideshow(success: @escaping (Slideshow) -> Void, failure: @escaping Failure) -> CancellableRequest {
        return request(for: AnythingEndpoint.fetchSlideshow, success: { (response: SlideshowResponse) in
            success(response.slideshow)
        }, failure: { error in
            failure(error)
        })
    }

    @discardableResult
    func postContact(_ contact: Contact, success: @escaping (Contact) -> Void, failure: @escaping Failure) -> CancellableRequest {
        return request(for: AnythingEndpoint.postContact(contact), success: { (response: ContactResponse) in
            success(response.form)
        }, failure: { error in
            failure(error)
        })
    }
}

private final class SlideshowResponse: Decodable {
    let slideshow: Slideshow
}

private final class ContactResponse: Decodable {
    let form: Contact
}
