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
    }
    
    func setupBarButtonItems() {
        navigationItem.leftBarButtonItem = cancelButtonItem

        navigationItem.rightBarButtonItems = [doneButtonItem/*, takeButtonItem*/]
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
            manager.fetchAssets() { [weak self] photos in
                
                guard let `self` = self else { return }
                
                self.updateEmptyView(count: photos.count)
                self.title = self.title(forAlbum: manager.selectedAlbum)
                self.collectionView.reloadData()
                
                if self.selectedArray.count > 0 {
                    // initialize preselected assets
                    self.selectedArray.forEach({ [weak self] (asset) in
                        if let row = photos.firstIndex(of: asset) {
                            let indexPathToSelect = IndexPath(row: row, section: 0)
                            self?.collectionView.selectItem(at: indexPathToSelect, animated: false, scrollPosition: UICollectionView.ScrollPosition(rawValue: 0))
                        }
                    })
                    self.updateSelectionCount()
                }
                if self.pickerConfig.assetsIsScrollToBottom {
                    let item = self.collectionView(self.collectionView, numberOfItemsInSection: 0) - 1
                    let lastItemIndex = NSIndexPath(item: item, section: 0)
                    self.collectionView.scrollToItem(at: lastItemIndex as IndexPath, at: .bottom, animated: false)
                } else {
                    self.collectionView.scrollToItem(at: IndexPath(row: 0, section: 0), at: .bottom, animated: false)
                }
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
