//
//  AssetsPickerViewController.swift
//  Pods
//
//  Created by DragonCherry on 5/17/17.
//
//

import UIKit
import TinyLog

// MARK: - AssetsPickerViewControllerDelegate
public protocol AssetsPickerViewControllerDelegate {
    
}

// MARK: - AssetsPickerViewController
open class AssetsPickerViewController: UISplitViewController {
    
    open var pickerDelegate: AssetsPickerViewControllerDelegate?
    
    open var pickerNavigation: AssetsPickerNavigationController = {
        let controller = AssetsPickerNavigationController()
        return controller
    }()
    
    open var photoViewController: AssetsPhotoViewController = {
        let controller = AssetsPhotoViewController()
        return controller
    }()
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        commonInit()
    }
    
    func commonInit() {
        viewControllers = [pickerNavigation, photoViewController]
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        presentsWithGesture = false
        preferredDisplayMode = .allVisible
        delegate = self
        
    }
    
    deinit {
        logd("Released \(type(of: self))")
    }
}

extension AssetsPickerViewController: UISplitViewControllerDelegate {
    
}
