//
//  AssetsPhotoViewController+Model.swift
//  AssetsPickerViewController
//
//  Created by DragonCherry on 2020/07/03.
//

import UIKit
import Photos

extension AssetsPhotoViewController {
    
    func logSelectStatus(_ indexPath: IndexPath? = nil, isSelect: Bool) {
        if LogConfig.isSelectLogEnabled {
            if let indexPath = indexPath {
                logd("\(isSelect ? "Selected" : "Deselected") index: \(indexPath.row), count: \(selectedMap.count)")
            } else {
                logd("count: \(selectedMap.count)")
            }
        }
    }
    
    func setSelectedAssets(assets: [PHAsset]) {
        defer { logSelectStatus(isSelect: true) }
        
        selectedArray.removeAll()
        selectedMap.removeAll()
        
        _ = assets.filter { AssetsManager.shared.isExist(asset: $0) }
            .map { [weak self] asset in
                guard let `self` = self else { return }
                self.selectedArray.append(asset)
                self.selectedMap.updateValue(asset, forKey: asset.localIdentifier)
        }
    }
    
    func isSelected(at indexPath: IndexPath) -> Bool {
        let manager = AssetsManager.shared
        guard indexPath.row < manager.assetArray.count else { return false }
        if let _ = selectedMap[manager.assetArray[indexPath.row].localIdentifier] {
            return true
        } else {
            return false
        }
    }
    
    func select(at indexPath: IndexPath) {
        defer { logSelectStatus(indexPath, isSelect: true) }
        let manager = AssetsManager.shared
        guard indexPath.row < manager.assetArray.count else { return }
        let asset = manager.assetArray[indexPath.row]
        if let _ = selectedMap[asset.localIdentifier] {} else {
            selectedArray.append(asset)
            selectedMap[asset.localIdentifier] = asset
        }
    }
    
    func deselect(at indexPath: IndexPath) {
        defer { logSelectStatus(indexPath, isSelect: false) }
        let manager = AssetsManager.shared
        guard indexPath.row < manager.assetArray.count else { return }
        let asset = manager.assetArray[indexPath.row]
        guard let targetAsset = selectedMap[asset.localIdentifier] else {
            logw("Invalid status.")
            return
        }
        guard let targetIndex = selectedArray.firstIndex(of: targetAsset) else {
            logw("Invalid status.")
            return
        }
        selectedArray.remove(at: targetIndex)
        selectedMap.removeValue(forKey: targetAsset.localIdentifier)
    }
}


// MARK: - Image Fetching IDs
extension AssetsPhotoViewController {
    
    func cancelFetching(at indexPath: IndexPath) {
        if let requestId = requestIdMap[indexPath] {
            requestIdMap.removeValue(forKey: indexPath)
            if LogConfig.isFetchLogEnabled { logd("Canceled ID: \(requestId) at: \(indexPath.row) (\(requestIdMap.count))") }
            AssetsManager.shared.cancelRequest(requestId: requestId)
        }
    }
    
    func registerFetching(requestId: PHImageRequestID, at indexPath: IndexPath) {
        requestIdMap[indexPath] = requestId
        if LogConfig.isFetchLogEnabled { logd("Registered ID: \(requestId) at: \(indexPath.row) (\(requestIdMap.count))") }
    }
    
    func removeFetching(indexPath: IndexPath) {
        if let requestId = requestIdMap[indexPath] {
            requestIdMap.removeValue(forKey: indexPath)
            if LogConfig.isFetchLogEnabled { logd("Removed ID: \(requestId) at: \(indexPath.row) (\(requestIdMap.count))") }
        }
    }
    
    func isFetching(indexPath: IndexPath) -> Bool {
        if let _ = requestIdMap[indexPath] {
            return true
        } else {
            return false
        }
    }
}
