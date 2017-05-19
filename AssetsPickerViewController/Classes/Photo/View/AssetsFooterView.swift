//
//  AssetsPhotoFooterView.swift
//  Pods
//
//  Created by DragonCherry on 5/18/17.
//
//

import UIKit

open class AssetsPhotoFooterView: UICollectionReusableView {
    
    private var didSetupConstraints: Bool = false
    
    internal lazy var button: UIView = {
        let button = UIButton.newAutoLayout()
        return button
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
        addSubview(button)
    }
    
    open override func updateConstraints() {
        if !didSetupConstraints {
            didSetupConstraints = true
        }
        super.updateConstraints()
    }
}
