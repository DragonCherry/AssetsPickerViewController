//
//  UIScreen+AssetsPickerViewController.swift
//  Pods
//
//  Created by DragonCherry on 5/19/17.
//
//

import UIKit

extension UIScreen {
    
    var portraitSize: CGSize {
        let size = UIScreen.main.bounds.size
        return CGSize(width: min(size.width, size.height), height: max(size.width, size.height))
    }
    
    var landscapeSize: CGSize {
        let size = UIScreen.main.bounds.size
        return CGSize(width: max(size.width, size.height), height: min(size.width, size.height))
    }
}
