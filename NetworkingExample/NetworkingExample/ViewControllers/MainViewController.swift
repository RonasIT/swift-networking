//
//  Created by Dmitry Frishbuter on 08/10/2018
//  Copyright © 2018 Ronas IT. All rights reserved.
//

import UIKit

final class MainViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func getButtonPressed(_ sender: UIButton) {
        navigationController?.pushViewController(UIStoryboard.main.slideshowViewController, animated: true)
    }

    @IBAction func postButtonPressed(_ sender: UIButton) {
        navigationController?.pushViewController(UIStoryboard.main.contactViewController, animated: true)
    }
}
