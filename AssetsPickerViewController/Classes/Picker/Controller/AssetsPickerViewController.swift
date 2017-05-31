//
//  AssetsPickerViewController.swift
//  Pods
//
//  Created by DragonCherry on 5/17/17.
//
//

import UIKit
import TinyLog
import Photos

// MARK: - AssetsPickerViewControllerDelegate
public protocol AssetsPickerViewControllerDelegate {
    func assetsPickerDidCancel(controller: AssetsPickerViewController)
    func assetsPickerCannotAccessPhotoLibrary(controller: AssetsPickerViewController)
    func assetsPicker(controller: AssetsPickerViewController, selected assets: [PHAsset])
    func assetsPicker(controller: AssetsPickerViewController, shouldSelect asset: PHAsset, at indexPath: IndexPath) -> Bool
    func assetsPicker(controller: AssetsPickerViewController, didSelect asset: PHAsset, at indexPath: IndexPath)
    func assetsPicker(controller: AssetsPickerViewController, shouldDeselect asset: PHAsset, at indexPath: IndexPath) -> Bool
    func assetsPicker(controller: AssetsPickerViewController, didDeselect asset: PHAsset, at indexPath: IndexPath)
}

// MARK: - AssetsPickerViewController
open class AssetsPickerViewController: UISplitViewController {
    
    open var pickerDelegate: AssetsPickerViewControllerDelegate?
    private var pickerConfig: AssetsPickerConfig!
    
    open var pickerNavigation: AssetsPickerNavigationController = {
        return AssetsPickerNavigationController()
    }()
    
    open lazy var photoViewController: AssetsPhotoViewController = {
        var config: AssetsPickerConfig!
        if let pickerConfig = self.pickerConfig {
            config = pickerConfig.prepare()
        } else {
            config = AssetsPickerConfig().prepare()
        }
        self.pickerConfig = config
        AssetsManager.shared.pickerConfig = config
        return AssetsPhotoViewController(pickerConfig: config)
    }()
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        commonInit()
    }
    
    public init(pickerConfig: AssetsPickerConfig) {
        self.pickerConfig = pickerConfig
        super.init(nibName: nil, bundle: nil)
        commonInit()
    }
    
    func commonInit() {
        AssetsManager.shared.registerObserver()
        viewControllers = [pickerNavigation, photoViewController]
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        presentsWithGesture = false
        preferredDisplayMode = .allVisible
        delegate = self
        
    }
    
    deinit {
        AssetsManager.shared.clear()
        logd("Released \(type(of: self))")
    }
}

extension AssetsPickerViewController: UISplitViewControllerDelegate {
    
}
