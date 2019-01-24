//
//  Created by Dmitry Frishbuter on 10/10/2018.
//  Copyright © 2018 Ronas IT. All rights reserved.
//

import UIKit
import Networking

final class SlideshowViewController: UIViewController {

    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var activityView: ActivityView!

    private lazy var apiService: ApiServiceProtocol = Services.apiService
    private let reachabilityService: ReachabilityServiceProtocol = Services.reachabilityService

    private var request: CancellableRequest?
    private var reachabilitySubscription: ReachabilitySubscription?

    private var slideshow: Slideshow?

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.register(SlideCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: SlideCollectionViewCell.self))

        loadSlideshow()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reachabilitySubscription = reachabilityService.subscribe { [weak self] isReachable in
            if !isReachable {
                self?.presentAlertController(withTitle: "Reachability", message: "You are not connected to the internet")
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        reachabilitySubscription?.unsubscribe()
        reachabilitySubscription = nil
    }

    private func loadSlideshow() {
        startLoading()
        request = apiService.fetchSlideshow(success: { [weak self] slideshow in
            guard let `self` = self else {
                return
            }
            self.stopLoading()
            self.slideshow = slideshow
            self.title = slideshow.author
            self.collectionView.reloadData()
        }, failure: { [weak self] error in
            guard let `self` = self else {
                return
            }
            self.stopLoading()
            self.presentAlertController(for: error)
        })
    }

    private func startLoading() {
        activityView.isHidden = false
        activityView.indicator.startAnimating()
    }

    private func stopLoading() {
        activityView.isHidden = true
        activityView.indicator.stopAnimating()
    }
}

// MARK: - UICollectionViewDataSource

extension SlideshowViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return slideshow?.slides.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let id = String(describing: SlideCollectionViewCell.self)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: id, for: indexPath) as! SlideCollectionViewCell
        if let slideshow = slideshow {
            cell.titleLabel.text = slideshow.slides[indexPath.item].title
        }
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension SlideshowViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: collectionView.bounds.width)
    }
}

// MARK: - UICollectionViewDelegate

extension SlideshowViewController: UICollectionViewDelegate {

}
