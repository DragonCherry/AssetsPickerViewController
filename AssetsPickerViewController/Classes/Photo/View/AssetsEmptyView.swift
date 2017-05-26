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
        super.commonInit()
        backgroundColor = .white
        set(title: String(key: "Title_No_Items"), message: String(key: "Message_No_Items"))
    }
}
