//
//  AssetsGuideView.swift
//  Pods
//
//  Created by DragonCherry on 5/26/17.
//
//

import Foundation
import SwiftARGB

open class AssetsGuideView: UIView {
    
    private var didSetupConstraints: Bool = false
    private let lineSpace: CGFloat = 10

    fileprivate lazy var messageLabel: UILabel = {
        let label = UILabel.newAutoLayout()
        label.textAlignment = .center
        label.numberOfLines = 10
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
    
    func commonInit() {
        backgroundColor = .white
        addSubview(messageLabel)
    }
    
    open override func updateConstraints() {
        if !didSetupConstraints {
            messageLabel.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20))
            didSetupConstraints = true
        }
        super.updateConstraints()
    }
    
    open func set(title: String, message: String) {
        let attributedString = NSMutableAttributedString()
        let attributedTitle = NSMutableAttributedString(string: "\(title)\n", attributes: [
            NSFontAttributeName: UIFont.systemFont(forStyle: UIFontTextStyle.title1),
            NSForegroundColorAttributeName: UIColor(rgbHex: 0x999999)
            ])
        let lineStyle = NSMutableParagraphStyle()
        lineStyle.lineSpacing = lineSpace
        let line = NSMutableAttributedString(string: "\n", attributes: [
            NSParagraphStyleAttributeName: lineStyle,
            NSFontAttributeName: UIFont.systemFont(ofSize: 1)
            ])
        let attributedDesc = NSMutableAttributedString(string: message, attributes: [
            NSFontAttributeName: UIFont.systemFont(forStyle: UIFontTextStyle.body),
            NSForegroundColorAttributeName: UIColor(rgbHex: 0x999999)
            ])
        attributedString.append(attributedTitle)
        attributedString.append(line)
        attributedString.append(attributedDesc)
        messageLabel.attributedText = attributedString
    }
}
