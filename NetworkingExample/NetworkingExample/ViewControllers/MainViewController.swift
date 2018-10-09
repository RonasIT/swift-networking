//
//  Created by Dmitry Frishbuter on 08/10/2018
//  Copyright © 2018 Ronas IT. All rights reserved.
//

import UIKit
import Networking
import Alamofire

final class MainViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    private func showDetails(for method: HTTPMethod) {
        let viewController: DetailViewController = UIStoryboard.main.viewController(withID: "DetailViewController")
        viewController.method = method
        navigationController?.pushViewController(viewController, animated: true)
    }

    @IBAction func getButtonPressed(_ sender: UIButton) {
        showDetails(for: .get)
    }

    @IBAction func postButtonPressed(_ sender: UIButton) {
        showDetails(for: .post)
    }
}
