//
//  AssetsPhotoCellOverlay.swift
//  Pods
//
//  Created by DragonCherry on 5/26/17.
//
//

import UIKit

open class AssetsPhotoCellOverlay: UIView {
    
    open var count: Int = 0 {
        didSet { countLabel.text = "\(count)" }
    }
    
    // MARK: - Views
    private var didSetupConstraints: Bool = false
    
    let countLabel: UILabel = {
        let label = UILabel.newAutoLayout()
        label.textAlignment = .center
        label.textColor = UIColor.white
        label.adjustsFontSizeToFitWidth = true
        label.font = UIFont.systemFont(forStyle: .subheadline)
        return label
    }()
    
    // MARK: - Lifecycle
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    private func commonInit() {
        dim(animated: false, color: .white, alpha: 0.25)
        addSubview(countLabel)
    }
    
    open override func updateConstraints() {
        if !didSetupConstraints {
            
            countLabel.autoMatch(.width, to: .width, of: self, withMultiplier: 0.2)
            countLabel.autoMatch(.height, to: .height, of: self, withMultiplier: 0.2)
            countLabel.autoPinEdge(.trailing, to: .trailing, of: self, withOffset: -5)
            countLabel.autoPinEdge(.bottom, to: .bottom, of: self, withOffset: -5)
            
            didSetupConstraints = true
        }
        super.updateConstraints()
    }
}
