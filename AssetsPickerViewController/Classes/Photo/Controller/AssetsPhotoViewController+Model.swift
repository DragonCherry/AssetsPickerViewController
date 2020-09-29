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
        guard let fetchResult = manager.fetchResult else { return false }
        guard indexPath.row < fetchResult.count else { return false }
        let asset = fetchResult.object(at: indexPath.row)
        if let _ = selectedMap[asset.localIdentifier] {
            return true
        } else {
            return false
        }
    }
    
    func select(at indexPath: IndexPath) {
        defer { logSelectStatus(indexPath, isSelect: true) }
        let manager = AssetsManager.shared
        guard let fetchResult = manager.fetchResult else { return }
        guard indexPath.row < fetchResult.count else { return }
        let asset = fetchResult.object(at: indexPath.row)
        if let _ = selectedMap[asset.localIdentifier] {} else {
            selectedArray.append(asset)
            selectedMap[asset.localIdentifier] = asset
        }
        if let delegate = self.delegate {
            delegate.assetsPicker?(controller: picker, didSelect: asset, at: indexPath)
        }
    }
    
    func deselect(at indexPath: IndexPath) {
        defer { logSelectStatus(indexPath, isSelect: false) }
        let manager = AssetsManager.shared
        guard let fetchResult = manager.fetchResult else { return }
        guard indexPath.row < fetchResult.count else { return }
        let asset = fetchResult.object(at: indexPath.row)
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
        
        if let delegate = self.delegate {
            delegate.assetsPicker?(controller: picker, didDeselect: asset, at: indexPath)
        }
    }
}
