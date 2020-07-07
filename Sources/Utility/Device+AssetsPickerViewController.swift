//
//  Device+AssetsPickerViewController.swift
//  AssetsPickerViewController
//
//  Created by DragonCherry on 19/12/2017.
//

import UIKit

class Device {
    static func safeAreaInsets(isPortrait: Bool) -> UIEdgeInsets {
        let size = isPortrait ? UIScreen.main.portraitSize : UIScreen.main.landscapeSize
        switch size.height {
        case 812:
            return isPortrait ? UIEdgeInsets(top: 88, left: 0, bottom: 34, right: 0) : UIEdgeInsets(top: 32, left: 44, bottom: 21, right: 44)
        default:
            return isPortrait ? UIEdgeInsets(top: 64, left: 0, bottom: 0, right: 0) : UIEdgeInsets(top: 30, left: 0, bottom: 0, right: 0)
        }
    }
}
