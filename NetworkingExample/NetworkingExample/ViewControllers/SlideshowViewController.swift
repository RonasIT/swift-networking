//
//  Created by Dmitry Frishbuter on 10/10/2018.
//  Copyright © 2018 Ronas IT. All rights reserved.
//

import UIKit
import Networking

final class SlideshowViewController: UIViewController {

    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var activityView: ActivityView!

    private lazy var apiService: ApiServiceProtocol = ServicesFactory.apiService
    private var request: Request?

    private var slideshow: Slideshow?

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.register(SlideCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: SlideCollectionViewCell.self))

        loadSlideshow()
    }

    private func loadSlideshow() {
        startLoading()
        request = apiService.fetchSlideshow(success: { [weak self] slideshow in
                self?.stopLoading()
                self?.slideshow = slideshow
                self?.title = slideshow.author
                self?.collectionView.reloadData()
            }, failure: { [weak self] error in
                self?.stopLoading()
                self?.presentAlertController(for: error)
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
