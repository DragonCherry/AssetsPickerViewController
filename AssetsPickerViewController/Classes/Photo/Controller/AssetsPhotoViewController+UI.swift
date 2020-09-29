//
//  AssetsPhotoViewController+UI.swift
//  AssetsPickerViewController
//
//  Created by DragonCherry on 2020/07/02.
//

import UIKit
import Photos

// MARK: - Internal APIs for UI
extension AssetsPhotoViewController {
    
    func updateEmptyView(count: Int) {
        let hasPermission = PHPhotoLibrary.authorizationStatus() == .authorized
        if hasPermission {
            if emptyView.isHidden {
                if count == 0 {
                    emptyView.isHidden = false
                }
            } else {
                if count > 0 {
                    emptyView.isHidden = true
                }
            }
        } else {
            emptyView.isHidden = true
        }
        logi("emptyView.isHidden: \(emptyView.isHidden), count: \(count)")
    }
    
    func updateNoPermissionView() {
        noPermissionView.isHidden = PHPhotoLibrary.authorizationStatus() == .authorized
        logi("isHidden: \(noPermissionView.isHidden)")
    }
    
    func updateLayout(layout: UICollectionViewLayout, isPortrait: Bool? = nil) {
        guard let flowLayout = layout as? UICollectionViewFlowLayout else { return }
        if let isPortrait = isPortrait {
            self.isPortrait = isPortrait
        }
        flowLayout.itemSize = self.isPortrait ? pickerConfig.assetPortraitCellSize(forViewSize: UIScreen.main.portraitContentSize) : pickerConfig.assetLandscapeCellSize(forViewSize: UIScreen.main.landscapeContentSize)
        flowLayout.minimumLineSpacing = self.isPortrait ? pickerConfig.assetPortraitLineSpace : pickerConfig.assetLandscapeLineSpace
        flowLayout.minimumInteritemSpacing = self.isPortrait ? pickerConfig.assetPortraitInteritemSpace : pickerConfig.assetLandscapeInteritemSpace
    }
    
    func selectCell(at indexPath: IndexPath) {
        collectionView.selectItem(at: indexPath, animated: false, scrollPosition: .init())
        guard var photoCell = collectionView.cellForItem(at: indexPath) as? AssetsPhotoCellProtocol else { return }
        photoCell.count = selectedArray.count
    }
    
    func deselectCell(at indexPath: IndexPath, isForced: Bool = false) {
        collectionView.deselectItem(at: indexPath, animated: false)
        guard isForced, var photoCell = collectionView.cellForItem(at: indexPath) as? AssetsPhotoCellProtocol else { return }
        photoCell.isSelected = false
    }
    
    func deselectOldestIfNeeded(isForced: Bool = false) {
        guard let fetchResult = AssetsManager.shared.fetchResult else { return }
        if selectedArray.count > pickerConfig.assetsMaximumSelectionCount, let firstSelectedAsset = selectedArray.first {
            let indexToDeselect = fetchResult.index(of: firstSelectedAsset)
            let indexPathToDeselect = IndexPath(row: indexToDeselect, section: 0)
            deselect(at: indexPathToDeselect)
            deselectCell(at: indexPathToDeselect, isForced: isForced)
        }
    }
    
    func select(album: PHAssetCollection) {
        loadingPlaceholderView.isHidden = false
        loadingActivityIndicatorView.startAnimating()
        AssetsManager.shared.selectAsync(album: album, completion: { [weak self] (successful, result) in
            guard let `self` = self else { return }
            guard successful else { return }
            guard let fetchResult = result else { return }
            self.collectionView.reloadData()
            self.scrollToLastItemIfNeeded()
            self.preselectItemsIfNeeded(result: fetchResult)
            self.updateNavigationStatus()
            self.loadingPlaceholderView.isHidden = true
            self.loadingActivityIndicatorView.stopAnimating()
        })
    }
    
    func updateCount(at indexPath: IndexPath) {
        // update selected UI
        guard var photoCell = collectionView.cellForItem(at: indexPath) as? AssetsPhotoCellProtocol else {
            logw("Invalid status.")
            return
        }
        photoCell.count = selectedArray.count
    }
    
    
    func scrollToLastItemIfNeeded() {
        guard let fetchResult = AssetsManager.shared.fetchResult else { return }
        guard !(fetchResult.count == 0) else { return }
        if pickerConfig.assetsIsScrollToBottom == true {
            self.collectionView.scrollToItem(at: IndexPath(row: fetchResult.count - 1, section: 0), at: .bottom, animated: false)
        } else {
            self.collectionView.scrollToItem(at: IndexPath(row: 0, section: 0), at: .bottom, animated: false)
        }
    }

    func preselectItemsIfNeeded(result: PHFetchResult<PHAsset>) {
        if selectedArray.count > 0 {
            // initialize preselected assets
            selectedArray.forEach({ [weak self] (asset) in
                let row = result.index(of: asset)
                let indexPathToSelect = IndexPath(row: row, section: 0)
                let scrollPosition = UICollectionView.ScrollPosition(rawValue: 0)
                self?.collectionView.selectItem(at: indexPathToSelect,
                                                animated: false,
                                                scrollPosition: scrollPosition)
            })
            updateSelectionCount()
        }
    }

    func updateSelectionCount() {
        let visibleIndexPaths = collectionView.indexPathsForVisibleItems
        guard let fetchResult = AssetsManager.shared.fetchResult else { return }
        for visibleIndexPath in visibleIndexPaths {
            guard fetchResult.count > visibleIndexPath.row else {
                loge("Referred wrong index\(visibleIndexPath.row) while asset count is \(fetchResult.count).")
                break
            }
            if let selectedAsset = selectedMap[fetchResult.object(at: visibleIndexPath.row).localIdentifier], var photoCell = collectionView.cellForItem(at: visibleIndexPath) as? AssetsPhotoCellProtocol {
                if let selectedIndex = selectedArray.firstIndex(of: selectedAsset) {
                    photoCell.count = selectedIndex + 1
                }
            }
        }
    }
    
    func updateNavigationStatus() {
        doneButtonItem.isEnabled = selectedArray.count >= (pickerConfig.assetsMinimumSelectionCount >= 0 ? pickerConfig.assetsMinimumSelectionCount : 1)
        
        if let album = AssetsManager.shared.selectedAlbum, selectedArray.isEmpty {
            title = self.title(forAlbum: album)
        } else {
            let counts: (imageCount: Int, videoCount: Int) = selectedArray.reduce((0, 0)) { (result, asset) -> (Int, Int) in
                let imageCount = asset.mediaType == .image ? 1 : 0
                let videoCount = asset.mediaType == .video ? 1 : 0
                return (result.0 + imageCount, result.1 + videoCount)
            }
            
            let imageCount = counts.imageCount
            let videoCount = counts.videoCount
            
            var titleString: String = title(forAlbum: AssetsManager.shared.selectedAlbum)
            
            if imageCount > 0 && videoCount > 0 {
                titleString = String(format: String(key: "Title_Selected_Items"), NumberFormatter.decimalString(value: imageCount + videoCount))
            } else {
                if imageCount > 0 {
                    if imageCount > 1 {
                        titleString = String(format: String(key: "Title_Selected_Photos"), NumberFormatter.decimalString(value: imageCount))
                    } else {
                        titleString = String(format: String(key: "Title_Selected_Photo"), NumberFormatter.decimalString(value: imageCount))
                    }
                } else if videoCount > 0 {
                    if videoCount > 1 {
                        titleString = String(format: String(key: "Title_Selected_Videos"), NumberFormatter.decimalString(value: videoCount))
                    } else {
                        titleString = String(format: String(key: "Title_Selected_Video"), NumberFormatter.decimalString(value: videoCount))
                    }
                }
            }
            title = titleString
        }
    }
    
    func updateFooter() {
        guard let footerView = collectionView.visibleSupplementaryViews(ofKind: UICollectionView.elementKindSectionFooter).last as? AssetsPhotoFooterView else {
            return
        }
        footerView.set(imageCount: AssetsManager.shared.count(ofType: .image), videoCount: AssetsManager.shared.count(ofType: .video))
    }
    
    func presentAlbumController(animated: Bool = true) {
        guard PHPhotoLibrary.authorizationStatus() == .authorized else { return }
        let controller = AssetsAlbumViewController(pickerConfig: self.pickerConfig)
        controller.delegate = self

        let navigationController = UINavigationController(rootViewController: controller)
        self.navigationController?.present(navigationController, animated: animated, completion: nil)
    }
    
    func title(forAlbum album: PHAssetCollection?) -> String {
        var titleString: String!
        if let albumTitle = album?.localizedTitle {
            titleString = "\(albumTitle) ▾"
        } else {
            titleString = ""
        }
        return titleString
    }
    
    func updateCachedAssets(force: Bool = false) {
        let isViewVisible = isViewLoaded && view.window != nil
        
        if !isViewVisible {
            return
        }
        
        let bounds = collectionView.bounds
        
        // The preheat window is twice the height of the visible rect
        var preheatRect = bounds
        preheatRect = preheatRect.insetBy(dx: 0.0, dy: -0.5 * preheatRect.height)
        
        // If scrolled by a "reasonable" amount...
        let delta = abs(preheatRect.midY - previousPreheatRect.midY)
        
        if (delta > (bounds.height / 3.0)) || force {
            var addedIndexPaths: [IndexPath] = []
            var removedIndexPaths: [IndexPath] = []
            
            computeDifferenceBetweenRect(previousPreheatRect, newRect: preheatRect, added: { (rect) in
                let indexPaths = getIndexPathsForElements(in: rect)
                addedIndexPaths.append(contentsOf: indexPaths)
            }) { (rect) in
                let indexPaths = getIndexPathsForElements(in: rect)
                removedIndexPaths.append(contentsOf: indexPaths)
            }
            
            let assetsToStartCaching = getAssets(at: addedIndexPaths)
            let assetsToStopCaching = getAssets(at: removedIndexPaths)
            
            let targetSize = pickerConfig.assetCacheSize
            AssetsManager.shared.cache(assets: assetsToStartCaching, size: targetSize)
            AssetsManager.shared.stopCache(assets: assetsToStopCaching, size: targetSize)
            self.previousPreheatRect = preheatRect
        }
    }
    
    func getIndexPathsForElements(in rect: CGRect) -> [IndexPath] {
        let allLayoutAttributes = collectionView.collectionViewLayout.layoutAttributesForElements(in: rect)
        guard let attributes = allLayoutAttributes else { return [] }
        guard attributes.count == 0 else { return [] }
        var indexPaths: [IndexPath] = []
        for attribut in attributes {
            indexPaths.append(attribut.indexPath)
        }
        return indexPaths
    }
    
    func getAssets(at indexPaths: [IndexPath]) -> [PHAsset] {
        if indexPaths.count == 0 { return [] }
        guard let fetchResult = AssetsManager.shared.fetchResult else { return [] }
        var asstes: [PHAsset] = []
        for indexPath in indexPaths {
            if indexPath.item < fetchResult.count && indexPath.item != 0 {
                let index = fetchResult.count - indexPath.item
                let asset = fetchResult.object(at: index)
                asstes.append(asset)
            }
        }
        return asstes
    }
    
    func computeDifferenceBetweenRect(_ oldRect: CGRect, newRect: CGRect, added: (CGRect) -> Void, removed: (CGRect) -> Void) {
        if newRect.intersects(oldRect) {
            let oldMaxY = oldRect.maxY
            let oldMinY = oldRect.minY
            let newMaxY = newRect.maxY
            let newMinY = newRect.minY
            
            if newMaxY > oldMaxY {
                let rect = CGRect(x: newRect.origin.x, y: oldMaxY, width: newRect.size.width, height: (newMaxY - oldMaxY))
                added(rect)
            }
            if oldMinY > newMinY {
                let rect = CGRect(x: newRect.origin.x, y: newMinY, width: newRect.size.width, height: oldMinY - newMinY)
                added(rect)
            }
            if newMaxY < oldMaxY {
                let rect = CGRect(x: newRect.origin.x, y: newMaxY, width: newRect.size.width, height: oldMaxY - newMaxY)
                removed(rect)
            }
            if oldMinY < newMinY {
                let rect = CGRect(x: newRect.origin.x, y: oldMinY, width: newRect.size.width, height: newMinY - oldMinY)
                removed(rect)
            }

        } else {
            added(newRect)
            removed(oldRect)
        }
    }
}
