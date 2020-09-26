//
//  PanoramaIconView.swift
//  AssetsPickerViewController
//
//  Created by DragonCherry on 05/01/2018.
//

import Foundation
import UIKit

open class PanoramaIconView: UIView {
    
    private var iconLayer: CAShapeLayer? = nil
    
    open var iconColor: UIColor = .white
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    public convenience init(frame: CGRect, color: UIColor) {
        self.init(frame: frame)
        self.iconColor = color
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        if let iconLayer = self.iconLayer {
            iconLayer.removeFromSuperlayer()
            self.iconLayer = nil
        }
        let iconLayer = shapeLayer(forPath: shapePath(forSize: bounds.size))
        layer.addSublayer(iconLayer)
        self.iconLayer = iconLayer
    }
    
    private func shapePath(forSize size: CGSize) -> UIBezierPath {
        
        let intensity: CGFloat = 0.44
        let controlRatio: CGFloat = 0.25
        
        let padding: CGFloat = 0
        let leftTop: CGPoint = CGPoint(x: padding, y: padding)
        let rightTop: CGPoint = CGPoint(x: size.width - padding, y: padding)
        let leftBottom: CGPoint = CGPoint(x: padding, y: size.height - padding)
        let rightBottom: CGPoint = CGPoint(x: size.width - padding, y: size.height - padding)
        
        let path = UIBezierPath()
        path.move(to: leftTop)
        path.addQuadCurve(
            to: CGPoint(x: size.width / 2, y: size.height / 2 * intensity),
            controlPoint: CGPoint(x: size.width / 2 * controlRatio, y: size.height / 2 * intensity))
        path.addQuadCurve(
            to: rightTop,
            controlPoint: CGPoint(x: size.width - (size.width / 2 * controlRatio), y: size.height / 2 * intensity))
        path.addLine(to: rightBottom)
        path.addQuadCurve(
            to: CGPoint(x: size.width / 2, y: size.height - (size.height / 2 * intensity)),
            controlPoint: CGPoint(x: size.width - (size.width / 2 * controlRatio), y: size.height - (size.height / 2 * intensity)))
        path.addQuadCurve(
            to: leftBottom,
            controlPoint: CGPoint(x: size.width / 2 * controlRatio, y: size.height - (size.height / 2 * intensity)))
        path.addLine(to: leftTop)
        path.close()
        return path
    }
    
    private func shapeLayer(forPath path: UIBezierPath) -> CAShapeLayer {
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = path.cgPath
        shapeLayer.strokeColor = iconColor.cgColor
        shapeLayer.fillColor = iconColor.cgColor
        return shapeLayer
    }
}
