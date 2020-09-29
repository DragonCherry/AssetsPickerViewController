//
//  AssetsPhotoViewController+Setup.swift
//  AssetsPickerViewController
//
//  Created by DragonCherry on 2020/07/02.
//

import UIKit

// MARK: - Initial Setups
extension AssetsPhotoViewController {
    
    func setupCommon() {
        view.backgroundColor = .ap_background
        cameraPicker.delegate = self
    }
    
    func setupBarButtonItems() {
        navigationItem.leftBarButtonItem = cancelButtonItem
        if pickerConfig.assetIsShowCameraButton {
            navigationItem.rightBarButtonItems = [doneButtonItem, takeButtonItem]
        } else {
            navigationItem.rightBarButtonItems = [doneButtonItem]
        }
        doneButtonItem.isEnabled = false
    }
    
    func setupCollectionView() {
        
        collectionView.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            
            if #available(iOS 11.0, *) {
                leadingConstraint = make.leading.equalToSuperview().inset(view.safeAreaInsets.left).constraint.layoutConstraints.first
                trailingConstraint = make.trailing.equalToSuperview().inset(view.safeAreaInsets.right).constraint.layoutConstraints.first
            } else {
                leadingConstraint = make.leading.equalToSuperview().constraint.layoutConstraints.first
                trailingConstraint = make.trailing.equalToSuperview().constraint.layoutConstraints.first
            }
            make.bottom.equalToSuperview()
        }
        
        emptyView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        noPermissionView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
    
    func setupPlaceholderView() {
        loadingPlaceholderView.isHidden = true
        if #available(iOS 13.0, *) {
            loadingPlaceholderView.backgroundColor = .systemBackground
        } else {
            loadingPlaceholderView.backgroundColor = .white
        }
        loadingPlaceholderView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
    
    func setupLoadActivityIndicatorView() {
        loadingActivityIndicatorView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
    }
    
    func setupAssets() {
        loadingPlaceholderView.isHidden = false
        loadingActivityIndicatorView.startAnimating()
        let manager = AssetsManager.shared
        manager.subscribe(subscriber: self)
        manager.fetchAlbums { _ in
            manager.fetchAssets() { [weak self] result in
                guard let `self` = self else { return }
                guard let fetchResult = result else { return }
                self.updateEmptyView(count: fetchResult.count)
                self.updateNavigationStatus()
                self.collectionView.reloadData()
                self.preselectItemsIfNeeded(result: fetchResult)
                self.scrollToLastItemIfNeeded()
                self.updateCachedAssets(force: true)
                // hide loading
                self.loadingPlaceholderView.isHidden = true
                self.loadingActivityIndicatorView.stopAnimating()
            }
        }
        
    }
    
    func setupGestureRecognizer() {
        if let _ = self.tapGesture {
            // ignore
        } else {
            let gesture = UITapGestureRecognizer(target: self, action: #selector(pressedTitle))
            navigationController?.navigationBar.addGestureRecognizer(gesture)
            gesture.delegate = self
            tapGesture = gesture
        }
    }
    
    func removeGestureRecognizer() {
        if let tapGesture = self.tapGesture {
            navigationController?.navigationBar.removeGestureRecognizer(tapGesture)
            self.tapGesture = nil
        }
    }
}
