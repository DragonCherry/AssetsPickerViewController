//
//  SimpleExampleController.swift
//  AssetsPickerViewController
//
//  Created by DraognCherry on 5/17/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit
import Photos
import AssetsPickerViewController
import TinyLog

class SimpleExampleController: UITableViewController {
    
    let kCellReuseIdentifier: String = UUID().uuidString
    var assets = [PHAsset]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.classForCoder(), forCellReuseIdentifier: kCellReuseIdentifier)
        tableView.tableFooterView = UIView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setToolbarHidden(false, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setToolbarHidden(true, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension SimpleExampleController {
    @IBAction func pressedClear(_ sender: Any) {
        assets.removeAll()
        tableView.reloadData()
    }
    
    @IBAction func pressedPick(_ sender: Any) {
        let picker = AssetsPickerViewController()
        picker.pickerDelegate = self
        present(picker, animated: true, completion: nil)
    }
}

extension SimpleExampleController: AssetsPickerViewControllerDelegate {
    
    func assetsPickerDidCancel(controller: AssetsPickerViewController) {
        logi("")
    }
    func assetsPicker(controller: AssetsPickerViewController, selected assets: [PHAsset], at indexPaths: [IndexPath]) {
        logi(indexPaths)
    }
    func assetsPicker(controller: AssetsPickerViewController, shouldSelect asset: PHAsset, at indexPath: IndexPath) -> Bool {
        logi(indexPath)
        return true
    }
    func assetsPicker(controller: AssetsPickerViewController, didSelect asset: PHAsset, at indexPath: IndexPath) {
        logi(indexPath)
    }
    func assetsPicker(controller: AssetsPickerViewController, shouldDeselect asset: PHAsset, at indexPath: IndexPath) -> Bool {
        logi(indexPath)
        return true
    }
    func assetsPicker(controller: AssetsPickerViewController, didDeselect asset: PHAsset, at indexPath: IndexPath) {
        logi(indexPath)
    }
}
