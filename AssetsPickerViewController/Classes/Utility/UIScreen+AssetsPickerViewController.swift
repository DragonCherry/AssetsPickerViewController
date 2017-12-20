//
//  UIScreen+AssetsPickerViewController.swift
//  Pods
//
//  Created by DragonCherry on 5/19/17.
//
//

import UIKit
import Device

extension UIScreen {
    
    var portraitSize: CGSize {
        let size = UIScreen.main.bounds.size
        return CGSize(width: min(size.width, size.height), height: max(size.width, size.height))
    }
    
    var landscapeSize: CGSize {
        let size = UIScreen.main.bounds.size
        return CGSize(width: max(size.width, size.height), height: min(size.width, size.height))
    }
    
    var portraitContentSize: CGSize {
        var size = UIScreen.main.portraitSize
        if #available(iOS 11.0, *) {
            size.width -= Device.safeAreaInsets(isPortrait: true).left + Device.safeAreaInsets(isPortrait: true).right
            size.height -= Device.safeAreaInsets(isPortrait: true).top + Device.safeAreaInsets(isPortrait: true).bottom
        }
        return size
    }
    
    var landscapeContentSize: CGSize {
        var size = UIScreen.main.landscapeSize
        if #available(iOS 11.0, *) {
            size.width -= Device.safeAreaInsets(isPortrait: false).left + Device.safeAreaInsets(isPortrait: false).right
            size.height -= Device.safeAreaInsets(isPortrait: false).top + Device.safeAreaInsets(isPortrait: false).bottom
        }
        return size
    }
}
