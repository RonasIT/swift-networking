//
//  Created by Nikita Zatsepilov on 05.02.2020
//  Copyright © 2020 Ronas IT. All rights reserved.
//

protocol ResponseType {
    associatedtype Result
    var result: Result { get }
}
