//
//  AssetsPhotoViewController+Delegate.swift
//  AssetsPickerViewController
//
//  Created by DragonCherry on 2020/07/02.
//

import UIKit
import Photos

// MARK: - UI Event Handlers
extension AssetsPhotoViewController {
    
    @objc func pressedCancel(button: UIBarButtonItem) {
        navigationController?.dismiss(animated: true, completion: {
            self.delegate?.assetsPicker?(controller: self.picker, didDismissByCancelling: true)
        })
        delegate?.assetsPickerDidCancel?(controller: picker)
    }
    
    @objc func pressedCamera(button: UIBarButtonItem) {
        cameraPicker.requestTake(parent: self)
    }
    
    @objc func pressedDone(button: UIBarButtonItem) {
        navigationController?.dismiss(animated: true, completion: {
            self.delegate?.assetsPicker?(controller: self.picker, didDismissByCancelling: false)
        })
        delegate?.assetsPicker(controller: picker, selected: selectedArray)
    }
    
    @objc func pressedTitle(gesture: UITapGestureRecognizer) {
        presentAlbumController()
    }
}

// MARK: - UIGestureRecognizerDelegate
extension AssetsPhotoViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard let navigationBar = navigationController?.navigationBar else { return false }
        let point = touch.location(in: navigationBar)
        // Ignore touches on navigation buttons on both sides.
        return point.x > navigationBar.bounds.width / 4 && point.x < navigationBar.bounds.width * 3 / 4
    }
}

// MARK: - UIScrollViewDelegate
extension AssetsPhotoViewController: UIScrollViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        logi("contentOffset: \(scrollView.contentOffset)")
        updateCachedAssets()
    }
}

// MARK: - AssetsAlbumViewControllerDelegate
extension AssetsPhotoViewController: AssetsAlbumViewControllerDelegate {
    
    public func assetsAlbumViewControllerCancelled(controller: AssetsAlbumViewController) {
        logi("Cancelled.")
    }
    
    public func assetsAlbumViewController(controller: AssetsAlbumViewController, selected album: PHAssetCollection) {
        select(album: album)
    }
}

@available(iOS 13.0, *)
extension AssetsPhotoViewController: UIContextMenuInteractionDelegate {
    public func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: { [weak self] in
            guard let `self` = self else { return nil }
            let pointInCollectionView = self.collectionView.convert(location, from: interaction.view)
            guard let pressingIndexPath = self.collectionView.indexPathForItem(at: pointInCollectionView) else { return nil }
            let previewController = AssetsPreviewController()
            guard let fetchResult = AssetsManager.shared.fetchResult else { return nil }
            previewController.asset = fetchResult.object(at: pressingIndexPath.row)
            return previewController
        }, actionProvider: nil)
    }
}

// MARK - UIViewControllerPreviewingDelegate
@available(iOS 9.0, *)
extension AssetsPhotoViewController: UIViewControllerPreviewingDelegate {
    
    public func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        logi("\(location)")
        guard !isDragSelectionEnabled else { return nil }
        guard let pressingIndexPath = collectionView.indexPathForItem(at: location) else { return nil }
        guard let pressingCell = collectionView.cellForItem(at: pressingIndexPath) else { return nil }
        previewingContext.sourceRect = pressingCell.frame
        let previewController = AssetsPreviewController()
        guard let fetchResult = AssetsManager.shared.fetchResult else { return nil }
        previewController.asset = fetchResult.object(at: pressingIndexPath.row)
        return previewController
    }
    
    public func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        logi("viewControllerToCommit: \(type(of: viewControllerToCommit))")
    }
}
