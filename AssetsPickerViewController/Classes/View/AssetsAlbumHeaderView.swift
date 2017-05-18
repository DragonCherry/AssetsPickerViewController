//
//  AssetsAlbumHeaderView.swift
//  Pods
//
//  Created by DragonCherry on 5/18/17.
//
//

import UIKit
import SwiftARGB

open class AssetsAlbumHeaderView: UICollectionReusableView {
    
    private var didSetupConstraints: Bool = false
    
    internal lazy var titleLabel: UILabel = {
        let label = UILabel.newAutoLayout()
        label.textColor = UIColor(rgbHex: 0x8C8C91)
        let font = UIFont.preferredFont(forTextStyle: .title2)
        label.font = UIFont.systemFont(ofSize: font.pointSize, weight: UIFontWeightRegular)
        label.text = String(key: "Title_Section_MyAlbums")
        return label
    }()
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    private func commonInit() {
        addSubview(titleLabel)
    }
    
    open override func updateConstraints() {
        if !didSetupConstraints {
            titleLabel.autoPinEdgesToSuperviewEdges()
            didSetupConstraints = true
        }
        super.updateConstraints()
    }
}
