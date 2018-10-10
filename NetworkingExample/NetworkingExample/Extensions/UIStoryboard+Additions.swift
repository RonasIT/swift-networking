//
//  Created by Dmitry Frishbuter on 09/10/2018.
//  Copyright © 2018 Ronas IT. All rights reserved.
//

import UIKit

extension UIStoryboard {

    static var main: UIStoryboard {
        return UIStoryboard(name: "Main", bundle: nil)
    }

    var mainViewController: MainViewController {
        return viewController(withID: "MainViewController")
    }

    var slideshowViewController: SlideshowViewController {
        return viewController(withID: "SlideshowViewController")
    }

    var contactViewController: ContactViewController {
        return viewController(withID: "ContactViewController")
    }

    func viewController<T: UIViewController>(withID id: String) -> T {
        guard let instantiatedVewController = instantiateViewController(withIdentifier: id) as? T else {
            fatalError("Unable to instantiate view controller with id \(id), type \(String(describing: T.self))")
        }
        return instantiatedVewController
    }
}
