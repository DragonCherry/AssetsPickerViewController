//
//  AssetsPhotoViewController+AssetsManager.swift
//  AssetsPickerViewController
//
//  Created by DragonCherry on 2020/07/02.
//

import UIKit
import Photos

// MARK: - AssetsManagerDelegate
extension AssetsPhotoViewController: AssetsManagerDelegate {
    
    public func assetsManager(manager: AssetsManager, authorizationStatusChanged oldStatus: PHAuthorizationStatus, newStatus: PHAuthorizationStatus) {
        if oldStatus != .authorized {
            if newStatus == .authorized {
                updateNoPermissionView()
                AssetsManager.shared.fetchAssets(isRefetch: true, completion: { [weak self] (_) in
                    self?.collectionView.reloadData()
                })
            }
        } else {
            updateNoPermissionView()
        }
    }
    
    public func assetsManager(manager: AssetsManager, reloadedAlbumsInSection section: Int) {}
    public func assetsManager(manager: AssetsManager, insertedAlbums albums: [PHAssetCollection], at indexPaths: [IndexPath]) {}
    
    public func assetsManager(manager: AssetsManager, removedAlbums albums: [PHAssetCollection], at indexPaths: [IndexPath]) {
        logi("removedAlbums at indexPaths: \(indexPaths)")
        guard let selectedAlbum = manager.selectedAlbum else {
            logw("selected album is nil.")
            return
        }
        if albums.contains(selectedAlbum) {
            manager.selectDefaultAlbum()
            updateNavigationStatus()
            updateFooter()
            collectionView.reloadData()
        }
    }
    
    public func assetsManager(manager: AssetsManager, updatedAlbums albums: [PHAssetCollection], at indexPaths: [IndexPath]) {}
    public func assetsManager(manager: AssetsManager, reloadedAlbum album: PHAssetCollection, at indexPath: IndexPath) {}
    
    public func assetsManager(manager: AssetsManager, insertedAssets assets: [PHAsset], at indexPaths: [IndexPath]) {
        logi("insertedAssets at: \(indexPaths)")
        
        var indexPathToSelect: IndexPath?
        
        if let newlySavedIdentifier = self.newlySavedIdentifier {
            self.newlySavedIdentifier = nil
            
            if let savedAssetEntry = AssetsManager.shared.assetArray.enumerated().first(where: { $0.element.localIdentifier == newlySavedIdentifier }) {
                let ip = IndexPath(row: savedAssetEntry.offset, section: 0)
                select(at: ip)
                collectionView.selectItem(at: ip, animated: false, scrollPosition: .init())
                indexPathToSelect = ip
            }
        }
        
        collectionView.insertItems(at: indexPaths)
        if let indexPathToSelect = indexPathToSelect {
            UIView.setAnimationsEnabled(false)
            collectionView.reloadItems(at: [indexPathToSelect])
            UIView.setAnimationsEnabled(true)
        }
        updateFooter()
    }
    
    public func assetsManager(manager: AssetsManager, removedAssets assets: [PHAsset], at indexPaths: [IndexPath]) {
        logi("removedAssets at: \(indexPaths)")
        for removedAsset in assets {
            if let index = selectedArray.firstIndex(of: removedAsset) {
                selectedArray.remove(at: index)
                selectedMap.removeValue(forKey: removedAsset.localIdentifier)
            }
        }
        collectionView.deleteItems(at: indexPaths)
        updateSelectionCount()
        updateNavigationStatus()
        updateFooter()
    }
    
    public func assetsManager(manager: AssetsManager, updatedAssets assets: [PHAsset], at indexPaths: [IndexPath]) {
        logi("updatedAssets at: \(indexPaths)")
        let indexPathsToReload = collectionView.indexPathsForVisibleItems.filter { indexPaths.contains($0) }
        collectionView.reloadItems(at: indexPathsToReload)
        updateNavigationStatus()
        updateFooter()
    }
}

extension AssetsPhotoViewController: AssetsPickerManagerDelegate {
    func assetsPickerManagerSavedAsset(identifier: String) {
        self.newlySavedIdentifier = identifier
    }
}
