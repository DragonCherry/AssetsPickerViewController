//
//  Bundle+AssetsPickerViewController.swift
//  Pods
//
//  Created by DragonCherry on 5/17/17.
//
//

import Foundation

extension Bundle {
    static var assetsPickerBundle: Bundle {
        if let path = Bundle(for: AssetsPickerViewController.classForCoder()).path(forResource: "AssetsPickerViewController", ofType: "bundle") {
            if let bundle = Bundle(path: path) {
                return bundle
            }
        }
        fatalError("Failed to find CocoaPods resource bundle.")
    }
}
