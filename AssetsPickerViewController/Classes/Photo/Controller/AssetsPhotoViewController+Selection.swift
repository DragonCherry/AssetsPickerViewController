//
//  AssetsPhotoViewController+Selection.swift
//  AssetsPickerViewController
//
//  Created by DragonCherry on 2020/07/03.
//

import UIKit
import Photos

private let kAssetsPhotoCellIndexPath            = "org.cocoapods.AssetsPickerViewController.AssetsPhotoCell.IndexPath"
private let kAssetsPhotoCellTapGestureRecognizer = "org.cocoapods.AssetsPickerViewController.AssetsPhotoCell.UITapGestureRecognizer"

// MARK: - UICollectionViewDelegate
extension AssetsPhotoViewController: UICollectionViewDelegate {
    @available(iOS 13.0, *)
    public func collectionView(_ collectionView: UICollectionView, shouldBeginMultipleSelectionInteractionAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    public func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        if LogConfig.isSelectLogEnabled { logi("shouldSelectItemAt: \(indexPath.row)") }
        return selectedArray.count < pickerConfig.assetsMaximumSelectionCount
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if LogConfig.isSelectLogEnabled { logi("didSelectItemAt: \(indexPath.row)") }
        deselectOldestIfNeeded()
        select(at: indexPath)
        selectCell(at: indexPath)
        updateSelectionCount()
        updateNavigationStatus()
    }
    
    public func collectionView(_ collectionView: UICollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool {
        if LogConfig.isSelectLogEnabled { logi("shouldDeselectItemAt: \(indexPath.row)") }
        return true
    }
    
    public func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if LogConfig.isSelectLogEnabled { logi("didDeselectItemAt: \(indexPath.row)") }
        deselect(at: indexPath)
        deselectCell(at: indexPath)
        updateSelectionCount()
        updateNavigationStatus()
    }
    
    @objc func pressedPhotoCell(gesture: UITapGestureRecognizer) {
        guard let indexPath = gesture.view?.get(kAssetsPhotoCellIndexPath) as? IndexPath else { return }
        let isSelectedCell = isSelected(at: indexPath)
        
        if let delegate = self.delegate {
            if isSelectedCell {
                let shouldDeselect = delegate.assetsPicker?(controller: picker, shouldDeselect: AssetsManager.shared.assetArray[indexPath.row], at: indexPath) ?? true
                guard shouldDeselect else { return }
            } else {
                let shouldSelect = delegate.assetsPicker?(controller: picker, shouldSelect: AssetsManager.shared.assetArray[indexPath.row], at: indexPath) ?? true
                guard shouldSelect else { return }
            }
        }
        
        if isSelectedCell {
            deselect(at: indexPath)
            deselectCell(at: indexPath)
        } else {
            deselectOldestIfNeeded()
            select(at: indexPath)
            selectCell(at: indexPath)
        }
        
        updateNavigationStatus()
        updateSelectionCount()
//        checkInconsistencyForSelection()
    }
    
    func registerTapGestureIfNeeded(cell: UICollectionViewCell, indexPath: IndexPath) {
        if let _ = cell.get(kAssetsPhotoCellTapGestureRecognizer) as? UITapGestureRecognizer {} else {
            let gesture = UITapGestureRecognizer(target: self, action: #selector(pressedPhotoCell(gesture:)))
            cell.addGestureRecognizer(gesture)
        }
        cell.set(indexPath, forKey: kAssetsPhotoCellIndexPath)
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
                if let _ = selectedMap[AssetsManager.shared.assetArray[selectedIndexPath.row].localIdentifier] {
                    
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
