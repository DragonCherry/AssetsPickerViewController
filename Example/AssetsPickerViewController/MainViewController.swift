//
//  ViewController.swift
//  AssetsPickerViewController
//
//  Created by DragonCherry on 05/17/2017.
//  Copyright (c) 2017 DragonCherry. All rights reserved.
//

import UIKit

class MainViewController: UITableViewController {
    
    let kCellReuseIdentifier: String = UUID().uuidString

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.classForCoder(), forCellReuseIdentifier: kCellReuseIdentifier)
        tableView.tableFooterView = UIView()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

