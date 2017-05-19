//
//  String+AssetsPickerViewController.swift
//  Pods
//
//  Created by DragonCherry on 5/17/17.
//
//

import Foundation

extension String {
    init(key: String) {
        self = NSLocalizedString(key, tableName: "AssetsPickerViewController", bundle: Bundle.assetsPickerBundle, value: key, comment: "")
    }
}
