//
//  AssetsPickerViewController.swift
//  Pods
//
//  Created by DragonCherry on 5/17/17.
//
//

import UIKit
import Photos

// MARK: - AssetsPickerViewControllerDelegate
@objc public protocol AssetsPickerViewControllerDelegate: class {
    @objc optional func assetsPickerDidCancel(controller: AssetsPickerViewController)
    @objc optional func assetsPickerCannotAccessPhotoLibrary(controller: AssetsPickerViewController)
    func assetsPicker(controller: AssetsPickerViewController, selected assets: [PHAsset])
    @objc optional func assetsPicker(controller: AssetsPickerViewController, shouldSelect asset: PHAsset, at indexPath: IndexPath) -> Bool
    @objc optional func assetsPicker(controller: AssetsPickerViewController, didSelect asset: PHAsset, at indexPath: IndexPath)
    @objc optional func assetsPicker(controller: AssetsPickerViewController, shouldDeselect asset: PHAsset, at indexPath: IndexPath) -> Bool
    @objc optional func assetsPicker(controller: AssetsPickerViewController, didDeselect asset: PHAsset, at indexPath: IndexPath)
    @objc optional func assetsPicker(controller: AssetsPickerViewController, didDismissByCancelling byCancel: Bool)
}

// MARK: - AssetsPickerViewController
open class AssetsPickerViewController: UINavigationController {
    
    @objc open weak var pickerDelegate: AssetsPickerViewControllerDelegate?
    open var selectedAssets: [PHAsset] {
        return photoViewController.selectedArray
    }
    
    open var isShowLog: Bool = false {
        didSet {
            TinyLog.isShowInfoLog = isShowLog
            TinyLog.isShowErrorLog = isShowLog
        }
    }
    public var pickerConfig: AssetsPickerConfig! {
        didSet {
            if let config = self.pickerConfig?.prepare() {
                AssetsManager.shared.pickerConfig = config
                photoViewController?.pickerConfig = config
            }
        }
    }
    
    public private(set) var photoViewController: AssetsPhotoViewController!
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        commonInit()
    }
    
    public convenience init() {
        self.init(nibName: nil, bundle: nil)
    }
    
    func commonInit() {
        let config = AssetsPickerConfig().prepare()
        self.pickerConfig = config
        AssetsManager.shared.pickerConfig = config
        let controller = AssetsPhotoViewController()
        controller.pickerConfig = config
        self.photoViewController = controller
        
        AssetsManager.shared.registerObserver()
        viewControllers = [photoViewController]
    }
    
    deinit {
        AssetsManager.shared.clear()
        logd("Released \(type(of: self))")
    }
}
