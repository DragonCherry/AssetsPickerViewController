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
        self = Bundle.assetsPickerBundle.localizedString(forKey: key, value: key, table: "AssetsPickerViewController")
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
