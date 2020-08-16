//
//  AssetsPhotoViewController+Selection.swift
//  AssetsPickerViewController
//
//  Created by DragonCherry on 2020/07/03.
//

import UIKit
import Photos


// MARK: - UICollectionViewDelegate
extension AssetsPhotoViewController: UICollectionViewDelegate {
    @available(iOS 13.0, *)
    public func collectionView(_ collectionView: UICollectionView, shouldBeginMultipleSelectionInteractionAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    public func collectionView(_ collectionView: UICollectionView, didBeginMultipleSelectionInteractionAt indexPath: IndexPath) {
        isDragSelectionEnabled = true
    }
    
    public func collectionViewDidEndMultipleSelectionInteraction(_ collectionView: UICollectionView) {
        isDragSelectionEnabled = false
    }
    
    public func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    public func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        if LogConfig.isSelectLogEnabled { logi("shouldSelectItemAt: \(indexPath.row)") }
        
        if let delegate = self.delegate {
            guard let fetchResult = AssetsManager.shared.fetchResult else { return false }
            let shouldSelect = delegate.assetsPicker?(controller: picker, shouldSelect: fetchResult.object(at: indexPath.row), at: indexPath) ?? true
            guard shouldSelect else { return false }
        }
        
        if isDragSelectionEnabled {
            if selectedArray.count < pickerConfig.assetsMaximumSelectionCount {
                select(at: indexPath)
                return true
            } else {
                return false
            }
        } else {    
            select(at: indexPath)
            return true
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if LogConfig.isSelectLogEnabled { logi("didSelectItemAt: \(indexPath.row)") }
        if !isDragSelectionEnabled {
            deselectOldestIfNeeded()
        }
        updateSelectionCount()
        updateNavigationStatus()
        checkInconsistencyForSelection()
    }
    
    public func collectionView(_ collectionView: UICollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool {
        if LogConfig.isSelectLogEnabled { logi("shouldDeselectItemAt: \(indexPath.row)") }
        if let delegate = self.delegate {
            guard let fetchResult = AssetsManager.shared.fetchResult else { return false }
            let shouldDeselect = delegate.assetsPicker?(controller: picker, shouldDeselect: fetchResult.object(at: indexPath.row), at: indexPath) ?? true
            guard shouldDeselect else { return false }
        }
        deselect(at: indexPath)
        return true
    }
    
    public func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if LogConfig.isSelectLogEnabled { logi("didDeselectItemAt: \(indexPath.row)") }
        updateSelectionCount()
        updateNavigationStatus()
        checkInconsistencyForSelection()
    }
}

extension AssetsPhotoViewController {
    func checkInconsistencyForSelection() {
        guard LogConfig.isSelectLogEnabled else { return }
        if let indexPathsForSelectedItems = collectionView.indexPathsForSelectedItems, !indexPathsForSelectedItems.isEmpty {
            if selectedArray.count != indexPathsForSelectedItems.count || selectedMap.count != indexPathsForSelectedItems.count {
                loge("selected item count not matched!")
                return
            }
            for selectedIndexPath in indexPathsForSelectedItems {
                guard let fetchResult = AssetsManager.shared.fetchResult else { return }
                if let _ = selectedMap[fetchResult.object(at: selectedIndexPath.row).localIdentifier] {
                    
                } else {
                    loge("selected item not found in local map!")
                }
            }
        } else {
            if !selectedMap.isEmpty || !selectedArray.isEmpty {
                loge("selected items not matched!")
            }
        }
    }
}
