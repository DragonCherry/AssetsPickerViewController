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
        label.isHidden = true
        return label
    }()
    
    let checkmark: SSCheckMark = {
        let view = SSCheckMark.newAutoLayout()
        return view
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
        addSubview(checkmark)
    }
    
    open override func updateConstraints() {
        if !didSetupConstraints {
            
            countLabel.autoPinEdgesToSuperviewEdges()
            
            checkmark.autoSetDimension(.width, toSize: 30)
            checkmark.autoSetDimension(.height, toSize: 30)
            checkmark.autoPinEdge(.trailing, to: .trailing, of: self, withOffset: -1)
            checkmark.autoPinEdge(.bottom, to: .bottom, of: self, withOffset: -1)
            
            didSetupConstraints = true
        }
        super.updateConstraints()
    }
}
