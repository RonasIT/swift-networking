//
//  Created by Dmitry Frishbuter on 09/10/2018.
//  Copyright © 2018 Ronas IT. All rights reserved.
//

import UIKit
import Networking

final class ContactViewController: UIViewController {

    @IBOutlet var activityView: ActivityView!
    @IBOutlet var tableView: UITableView!

    private let apiService: ApiServiceProtocol = Services.apiService
    private var request: CancellableRequest?
    private var contact: Contact?

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: String(describing: UITableViewCell.self))
        postContact(Contact(id: "345", name: "James", url: URL(string: "https://www.jamesexample.com")!))
    }

    private func presentAlert(for error: Error) {
        let actions = [UIAlertAction(title: "OK", style: .default, handler: nil)]
        let alertController = UIAlertController(title: "Error", message: error.localizedDescription,
                                                preferredStyle: .alert, actions: actions)
        present(alertController, animated: true)
    }

    private func startLoading() {
        activityView.isHidden = false
        activityView.indicator.startAnimating()
    }

    private func stopLoading() {
        activityView.isHidden = true
        activityView.indicator.stopAnimating()
    }

    private func postContact(_ contact: Contact) {
        startLoading()
        apiService.postContact(contact, success: { [weak self] result in
                self?.stopLoading()
                self?.contact = result
                self?.tableView.reloadData()
            }) { [weak self] error in
                self?.stopLoading()
                self?.presentAlertController(for: error)
            }
    }
}

// MARK: - UITableViewDataSource

extension ContactViewController: UITableViewDataSource {

    enum Index: Int {
        case id, name, url
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard self.tableView(tableView, numberOfRowsInSection: section) != 0 else {
            return nil
        }
        return "Contact"
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: UITableViewCell.self))!
        switch Index(rawValue: indexPath.row)! {
        case .id:
            cell.textLabel?.text = "id: \(contact?.id ?? "")"
        case .name:
            cell.textLabel?.text = "name: \(contact?.name ?? "")"
        case .url:
            cell.textLabel?.text = "url: \(contact?.url.absoluteString ?? "")"
        }
        return cell
    }
}

// MARK: - UITableViewDelegate

extension ContactViewController: UITableViewDelegate {

}
