//
//  AssetsViewController.swift
//  Pods
//
//  Created by DragonCherry on 5/17/17.
//
//

import UIKit
import TinyLog

open class AssetsViewController: UIViewController {
    
    lazy var cancelButtonItem: UIBarButtonItem = {
        let buttonItem = UIBarButtonItem(title: String(key: "Cancel"), style: .plain, target: self, action: #selector(pressedCancel(button:)))
        return buttonItem
    }()
    
    lazy var viewModel: AssetsViewModel = {
        let vm = AssetsViewModel()
        vm.delegate = self
        return vm
    }()
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        title = String(key: "Photos")
        view.backgroundColor = .white
        navigationItem.leftBarButtonItem = cancelButtonItem
    }
}

extension AssetsViewController {
    
    func pressedCancel(button: UIBarButtonItem) {
        splitViewController?.dismiss(animated: true, completion: nil)
    }
}

extension AssetsViewController: AssetsViewModelDelegate {
    
}
