//
//  AssetsEmptyView.swift
//  Pods
//
//  Created by DragonCherry on 5/26/17.
//
//

import UIKit
import SwiftARGB

open class AssetsEmptyView: AssetsGuideView {
    
    override func commonInit() {
        set(title: String(key: "Title_No_Items"), message: String(format: String(key: "Message_No_Items"), UIDevice.current.model))
        titleStyle = .title2
        super.commonInit()
    }
}
