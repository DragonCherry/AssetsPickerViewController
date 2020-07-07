//
//  Bundle+AssetsPickerViewController.swift
//  Pods
//
//  Created by DragonCherry on 5/17/17.
//
//

import Foundation

extension Bundle {
    
    private static let kAssetsPickerResourceName = "AssetsPickerViewController"
    private static let kAssetsPickerResourceType = "bundle"
    
    static let assetsRootBundle: Bundle = {
        return Bundle(for: AssetsPickerViewController.classForCoder())
    }()
    
    static let assetsPickerPath: String? = {
        return Bundle.assetsRootBundle.path(forResource: Bundle.kAssetsPickerResourceName, ofType: Bundle.kAssetsPickerResourceType)
    }()
    
    static var assetsPickerBundle: Bundle {
        if let path = assetsPickerPath {
            if let bundle = Bundle(path: path) {
                return bundle
            } else {
                logw("Failed to get localized bundle.")
            }
        }
        return assetsRootBundle
    }
}
