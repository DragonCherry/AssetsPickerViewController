//
//  UIFont+AssetsPickerViewController.swift
//  Pods
//
//  Created by DragonCherry on 5/19/17.
//
//

import UIKit

extension UIFont {
    static func systemFont(forStyle style: UIFont.TextStyle, weight: Weight = UIFont.Weight.regular) -> UIFont {
        let font = UIFont.preferredFont(forTextStyle: style)
        return UIFont.systemFont(ofSize: font.pointSize, weight: weight)
    }
}

