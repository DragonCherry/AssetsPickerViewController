//
//  AssetsPhotoViewController+Collection.swift
//  AssetsPickerViewController
//
//  Created by DragonCherry on 2020/07/03.
//

import UIKit
import Photos

// MARK: - UICollectionViewDataSource
extension AssetsPhotoViewController: UICollectionViewDataSource {
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let count = AssetsManager.shared.fetchResult?.count ?? 0
        updateEmptyView(count: count)
        return count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellReuseIdentifier, for: indexPath)
        guard var photoCell = cell as? AssetsPhotoCellProtocol else {
            logw("Failed to cast UICollectionViewCell.")
            return cell
        }
        if let asset = AssetsManager.shared.fetchResult?.object(at: indexPath.row) {
            photoCell.asset = asset
            photoCell.isVideo = asset.mediaType == .video
            if photoCell.isVideo {
                photoCell.duration = asset.duration
            }
        } else {
            photoCell.asset = nil
        }
        
        if #available(iOS 13.0, *) {
            let interaction = UIContextMenuInteraction(delegate: self)
            cell.addInteraction(interaction)
        }
        
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard var photoCell = cell as? AssetsPhotoCellProtocol else {
            logw("Failed to cast UICollectionViewCell.")
            return
        }
        
        if let asset = AssetsManager.shared.fetchResult?.object(at: indexPath.row) {
            photoCell.asset = asset
            photoCell.isVideo = asset.mediaType == .video
            if photoCell.isVideo {
                photoCell.duration = asset.duration
            }
            
            if let selectedAsset = selectedMap[asset.localIdentifier] {
                if let targetIndex = selectedArray.firstIndex(of: selectedAsset) {
                    photoCell.count = targetIndex + 1
                }
            }
        } else {
            photoCell.asset = nil
        }
        
        tryFetchImage(forCell: photoCell, forIndexPath: indexPath)
        
        if LogConfig.isCellLogEnabled {
            logd("[\(indexPath.row)] isSelected: \(photoCell.isSelected), isVideo: \(photoCell.isVideo), count: \(photoCell.count)")
        }
    }
    
    func tryFetchImage(forCell cell: AssetsPhotoCellProtocol, forIndexPath indexPath: IndexPath, isRetry: Bool = false) {
        let requestId = AssetsManager.shared.image(at: indexPath.row, size: pickerConfig.assetCacheSize, completion: { [weak self] (image, isDegraded) in
            guard let fetchService = self?.fetchService else { return }
            guard fetchService.isFetching(indexPath: indexPath) else { return }
            if !isDegraded {
                fetchService.removeFetching(indexPath: indexPath)
            }
            UIView.transition(
                with: cell.imageView,
                duration: 0.125,
                options: .transitionCrossDissolve,
                animations: { [weak self] in
                    if let image = image, image.size.height > 0, image.size.height > 0 {
                        cell.imageView.image = image
                    } else {
                        if !isRetry {
                            self?.tryFetchImage(forCell: cell, forIndexPath: indexPath, isRetry: true)
                        } else {
                            logw("Failed to set right image at \(indexPath)")
                        }
                    }
            },
                completion: nil
            )
        })
        fetchService.registerFetching(requestId: requestId, at: indexPath)
    }
    
    public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        fetchService.cancelFetching(at: indexPath)
    }
    
    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard let footerView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: footerReuseIdentifier, for: indexPath) as? AssetsPhotoFooterView else {
            logw("Failed to cast AssetsPhotoFooterView.")
            return AssetsPhotoFooterView()
        }
        footerView.setNeedsUpdateConstraints()
        footerView.updateConstraintsIfNeeded()
        footerView.set(imageCount: AssetsManager.shared.count(ofType: .image), videoCount: AssetsManager.shared.count(ofType: .video))
        return footerView
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension AssetsPhotoViewController: UICollectionViewDelegateFlowLayout {
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        if collectionView.numberOfSections - 1 == section {
            if collectionView.bounds.width > collectionView.bounds.height {
                return CGSize(width: collectionView.bounds.width, height: pickerConfig.assetLandscapeCellSize(forViewSize: collectionView.bounds.size).width * 2/3)
            } else {
                return CGSize(width: collectionView.bounds.width, height: pickerConfig.assetPortraitCellSize(forViewSize: collectionView.bounds.size).width * 2/3)
            }
        } else {
            return .zero
        }
    }
}

// MARK: - UICollectionViewDataSourcePrefetching
extension AssetsPhotoViewController: UICollectionViewDataSourcePrefetching {
    public func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        var assets = [PHAsset]()
        for indexPath in indexPaths {
            let count = AssetsManager.shared.fetchResult?.count ?? 0
            if count > indexPath.row {
                guard let asset = AssetsManager.shared.fetchResult?.object(at: indexPath.row) else { return }
                assets.append(asset)
            }
        }
        AssetsManager.shared.cache(assets: assets, size: pickerConfig.assetCacheSize)
    }
}
