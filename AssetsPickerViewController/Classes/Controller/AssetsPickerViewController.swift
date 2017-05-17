//
//  AssetsPickerViewController.swift
//  Pods
//
//  Created by DragonCherry on 5/17/17.
//
//

import UIKit

open class AssetsPickerViewController: UISplitViewController {
    
    open var assetsPickerNavigation: AssetsPickerNavigationController = {
        let controller = AssetsPickerNavigationController()
        return controller
    }()
    
    open var assetsViewController: AssetsViewController = {
        let controller = AssetsViewController()
        return controller
    }()
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        delegate = self
    }
}

extension AssetsPickerViewController: UISplitViewControllerDelegate {
    public func splitViewController(_ svc: UISplitViewController, willChangeTo displayMode: UISplitViewControllerDisplayMode) {
        
    }
}
