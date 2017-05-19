//
//  AssetsPhotoViewController.swift
//  Pods
//
//  Created by DragonCherry on 5/17/17.
//
//

import UIKit
import Photos
import TinyLog

// MARK: - AssetsPhotoViewController
open class AssetsPhotoViewController: UIViewController {
    
    lazy var cancelButtonItem: UIBarButtonItem = {
        let buttonItem = UIBarButtonItem(title: String(key: "Cancel"), style: .plain, target: self, action: #selector(pressedCancel(button:)))
        return buttonItem
    }()
    lazy var doneButtonItem: UIBarButtonItem = {
        let buttonItem = UIBarButtonItem(title: String(key: "Done"), style: .plain, target: self, action: #selector(pressedDone(button:)))
        return buttonItem
    }()
    
    fileprivate var tapGesture: UITapGestureRecognizer?
    fileprivate var selectedAlbum: PHAssetCollection?
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        setupCommon()
        setupBarButtonItems()
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupGestureRecognizer()
    }
    
    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        removeGestureRecognizer()
    }
    
    deinit {
        logd("Released \(type(of: self))")
    }
}

// MARK: - Initial Setups
extension AssetsPhotoViewController {
    open func setupCommon() {
        title = String(key: "Title_Assets")
        view.backgroundColor = .white
    }
    
    open func setupBarButtonItems() {
        navigationItem.leftBarButtonItem = cancelButtonItem
        navigationItem.rightBarButtonItem = doneButtonItem
    }
    
    open func setupGestureRecognizer() {
        if let _ = self.tapGesture {
            
        } else {
            let gesture = UITapGestureRecognizer(target: self, action: #selector(pressedTitle))
            navigationController?.navigationBar.addGestureRecognizer(gesture)
            tapGesture = gesture
        }
    }
    
    open func removeGestureRecognizer() {
        if let tapGesture = self.tapGesture {
            navigationController?.navigationBar.removeGestureRecognizer(tapGesture)
            self.tapGesture = nil
        }
    }
}

// MARK: - UI Event Handlers
extension AssetsPhotoViewController {
    
    func pressedCancel(button: UIBarButtonItem) {
        splitViewController?.dismiss(animated: true, completion: nil)
    }
    
    func pressedDone(button: UIBarButtonItem) {
        splitViewController?.dismiss(animated: true, completion: nil)
    }
    
    func pressedTitle(gesture: UITapGestureRecognizer) {
        let navigationController = UINavigationController()
        let controller = AssetsAlbumViewController()
        controller.delegate = self
        navigationController.viewControllers = [controller]
        present(navigationController, animated: true, completion: nil)
    }
}

// MARK: - AssetsAlbumViewControllerDelegate
extension AssetsPhotoViewController: AssetsAlbumViewControllerDelegate {
    
    public func assetsAlbumViewControllerCancelled(controller: AssetsAlbumViewController) {
        log("")
    }
    
    public func assetsAlbumViewController(controller: AssetsAlbumViewController, selected album: PHAssetCollection) {
        selectedAlbum = album
    }
}

// MARK: - AssetsManagerDelegate
extension AssetsPhotoViewController: AssetsManagerDelegate {
    
    public func assetsManagerLoaded(manager: AssetsManager) {
        
    }
    public func assetsManager(manager: AssetsManager, removedSection section: Int) {
        
    }
    public func assetsManager(manager: AssetsManager, removedAlbums: [PHAssetCollection], at indexPaths: [IndexPath]) {
        
    }
    public func assetsManager(manager: AssetsManager, addedAlbums: [PHAssetCollection], at indexPaths: [IndexPath]) {
        
    }
}
