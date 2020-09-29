//
//  UIScreen+AssetsPickerViewController.swift
//  Pods
//
//  Created by DragonCherry on 5/19/17.
//
//

import UIKit

extension UIScreen {
    static func safeAreaInsets(isPortrait: Bool) -> UIEdgeInsets {
        let w: Double = Double(UIScreen.main.bounds.width)
        let h: Double = Double(UIScreen.main.bounds.height)
        let screenHeight: Double = max(w, h)

        switch screenHeight {
        case 812: // 5.8" (iPhone X/XS/XR/11)
            return isPortrait ? UIEdgeInsets(top: 88, left: 0, bottom: 34, right: 0) : UIEdgeInsets(top: 32, left: 44, bottom: 21, right: 44)
        default:
            return isPortrait ? UIEdgeInsets(top: 64, left: 0, bottom: 0, right: 0) : UIEdgeInsets(top: 30, left: 0, bottom: 0, right: 0)
        }
    }
    
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
            size.width -= UIScreen.safeAreaInsets(isPortrait: true).left + UIScreen.safeAreaInsets(isPortrait: true).right
            size.height -= UIScreen.safeAreaInsets(isPortrait: true).top + UIScreen.safeAreaInsets(isPortrait: true).bottom
        }
        return size
    }
    
    var landscapeContentSize: CGSize {
        var size = UIScreen.main.landscapeSize
        if #available(iOS 11.0, *) {
            size.width -= UIScreen.safeAreaInsets(isPortrait: false).left + UIScreen.safeAreaInsets(isPortrait: false).right
            size.height -= UIScreen.safeAreaInsets(isPortrait: false).top + UIScreen.safeAreaInsets(isPortrait: false).bottom
        }
        return size
    }
}
