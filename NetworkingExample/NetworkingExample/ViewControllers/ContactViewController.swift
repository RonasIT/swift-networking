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
    private let reachabilityService: ReachabilityServiceProtocol = Services.reachabilityService

    private var request: CancellableRequest?
    private var reachabilitySubscription: ReachabilitySubscription?

    private var contact: Contact?

    deinit {
        request?.cancel()
        reachabilitySubscription?.unsubscribe()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: String(describing: UITableViewCell.self))

        if reachabilityService.isReachable {
            postContact(makeContact())
        } else {
            presentNoConnectionAlert()
        }

        reachabilitySubscription = reachabilityService.subscribe { [weak self] isReachable in
            guard let `self` = self else {
                return
            }
            if isReachable, self.contact == nil {
                self.postContact(self.makeContact())
            }
        }
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
        guard reachabilityService.isReachable else {
            presentNoConnectionAlert()
            return
        }

        startLoading()
        request = apiService.postContact(contact, success: { [weak self] contact in
            guard let `self` = self else {
                return
            }
            self.stopLoading()
            self.contact = contact
            self.tableView.reloadData()
        }, failure: { [weak self] error in
            guard let `self` = self else {
                return
            }
            self.stopLoading()
            self.presentAlertController(for: error)
        })
    }

    private func presentNoConnectionAlert() {
        presentAlertController(withTitle: "Oops", message: "You are not connected to the internet")
    }

    private func makeContact() -> Contact {
        return Contact(id: "345", name: "James", url: URL(string: "https://www.jamesexample.com")!)
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

extension ContactViewController: UITableViewDelegate {}
