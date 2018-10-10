//
//  Created by Dmitry Frishbuter on 09/10/2018.
//  Copyright © 2018 Ronas IT. All rights reserved.
//

import UIKit

extension UIAlertController {

    convenience init(title: String?, message: String?, preferredStyle: UIAlertController.Style, actions: [UIAlertAction]) {
        self.init(title: title, message: message, preferredStyle: preferredStyle)
        add(actions)
    }

    func addAction(withTitle title: String?, style: UIAlertAction.Style = .default, handler: ((UIAlertAction) -> Void)? = nil) {
        let action = UIAlertAction(title: title, style: style, handler: handler)
        add(action)
    }

    func add(_ action: UIAlertAction) {
        addAction(action)
    }

    func add(_ actions: UIAlertAction...) {
        add(actions)
    }

    func add(_ actions: [UIAlertAction]) {
        actions.forEach(addAction)
    }
}

extension UIViewController {

    func presentAlertController(for error: Error) {
        let actions = [UIAlertAction(title: "OK", style: .default, handler: nil)]
        let alertController = UIAlertController(title: "Error", message: error.localizedDescription,
                                                preferredStyle: .alert, actions: actions)
        present(alertController, animated: true)
    }
}
