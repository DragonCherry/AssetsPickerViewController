//
//  AssetsPickerViewController.swift
//  Pods
//
//  Created by DragonCherry on 5/17/17.
//
//

import UIKit

public protocol AssetsPickerViewControllerDelegate {
    
}

open class AssetsPickerViewController: UISplitViewController {
    
    open var pickerDelegate: AssetsPickerViewControllerDelegate?
    
    open var assetsPickerNavigation: AssetsPickerNavigationController = {
        let controller = AssetsPickerNavigationController()
        return controller
    }()
    
    open var assetsViewController: AssetsViewController = {
        let controller = AssetsViewController()
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
        viewControllers = [assetsPickerNavigation, assetsViewController]
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        presentsWithGesture = false
        preferredDisplayMode = .allVisible
        delegate = self
        
    }
}

extension AssetsPickerViewController: UISplitViewControllerDelegate {
    
}
