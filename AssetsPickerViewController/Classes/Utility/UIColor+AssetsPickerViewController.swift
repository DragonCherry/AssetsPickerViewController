//
//  UIColor+AssetsPickerViewController.swift
//  AssetsPickerViewController
//
//  Created by DragonCherry on 07/10/2019.
//

import Foundation
import UIKit

extension UIColor {
    
    static var ap_label: UIColor {
        if #available(iOS 13.0, *) {
            return .label
        } else {
            return .black
        }
    }
    
    static var ap_secondaryLabel: UIColor {
        if #available(iOS 13.0, *) {
            return .secondaryLabel
        } else {
            return UIColor(rgbHex: 0x8C8C91)
        }
    }
    
    static var ap_background: UIColor {
        if #available(iOS 13.0, *) {
            return .systemBackground
        } else {
            return .white
        }
    }
    
    static var ap_cellBackground: UIColor {
        if #available(iOS 13.0, *) {
            return .secondarySystemBackground
        } else {
            return UIColor(rgbHex: 0xF0F0F0)
        }
    }
}
