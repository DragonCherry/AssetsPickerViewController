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
        guard
            let customConfig = AssetsPickerConfig.customStringConfig,
            let localizedKey = AssetsPickerLocalizedStringKey(rawValue: key),
            let string = customConfig[localizedKey] else {
#if SWIFT_PACKAGE
                self = Bundle.module.localizedString(forKey: key, value: key, table:  "AssetsPickerViewController")
#else
                self = Bundle.assetsPickerBundle.localizedString(forKey: key, value: key, table:  "AssetsPickerViewController")
#endif
                return
        }
        self = string
    }

    init(duration: TimeInterval) {
        let hour = Int(duration / 3600)
        let min = Int((duration / 60).truncatingRemainder(dividingBy: 60))
        let sec = Int(duration.truncatingRemainder(dividingBy: 60))
        var durationString = hour > 0 ? "\(hour)" : ""
        durationString.append(min > 0 ? "\(min):" : "0:")
        durationString.append(String(format: "%02d", sec))
        self = durationString
    }
}

