//
//  UIView+Dimmer.swift
//  Pods
//
//  Created by DragonCherry on 5/12/17.
//
//

import UIKit
import SnapKit

fileprivate let kDimmerViewKey                          = "kDimmerViewKey"
fileprivate let kDimmerView                             = "kDimmerView"
fileprivate let kDimmerViewRatio                        = "kDimmerViewRatio"
fileprivate let kDimmerActivityIndicatorView            = "kDimmerActivityIndicatorView"

fileprivate let kDimmerLayoutConstraints                = "kDimmerLayoutConstraints"
fileprivate let kDimmerWidthConstraint                  = "kDimmerWidthConstraint"
fileprivate let kDimmerHeightConstraint                 = "kDimmerHeightConstraint"

public enum DimmerEffectDirection {
    case solid
    case fromTop
    case fromLeft
    case fromBottom
    case fromRight
}

// MARK: - Dimming
extension UIView {
    
    var dimmerKey: String? {
        get { return get(kDimmerViewKey) as? String }
        set { set(newValue, forKey: kDimmerViewKey) }
    }
    
    open var dimmingRatio: CGFloat {
        get { return CGFloat((get(kDimmerViewRatio) as? CGFloat) ?? 0) }
        set { set(newValue, forKey: kDimmerViewRatio) }
    }
    
    open var isDimming: Bool {
        if let dimmerView = dimmerView, !dimmerView.isHidden && dimmingRatio > 0 {
            return true
        } else {
            return false
        }
    }
    
    open var dimmerView: UIView? {
        get { return get(dimmerKey ?? kDimmerView) as? UIView }
        set {
            if let newDimmerView = newValue {
                if let oldDimmerView = dimmerView {
                    if oldDimmerView !== newDimmerView {
                        clearKVO()
                    }
                }
                set(newDimmerView, forKey: dimmerKey ?? kDimmerView)
            } else {
                if let _ = dimmerView {
                    clearKVO()
                }
            }
        }
    }
    
    open var dimmerActivityView: UIView? {
        get { return get(kDimmerActivityIndicatorView) as? UIView }
        set {
            if let newDimmerActivityView = newValue {
                if let oldDimmerActivityView = dimmerActivityView {
                    if oldDimmerActivityView !== newDimmerActivityView {
                        clearKVO()
                    }
                }
                set(newDimmerActivityView, forKey: kDimmerActivityIndicatorView)
            } else {
                if let _ = dimmerActivityView {
                    clearKVO()
                }
            }
        }
    }
    
    fileprivate func createDimmerView(color: UIColor = .black, alpha: CGFloat = 0.4, isBlock: Bool = false) -> UIView {
        let view = UIView()
        view.backgroundColor = color
        view.alpha = alpha
        view.isUserInteractionEnabled = isBlock
        return view
    }
    
    fileprivate func createDimmerActivityView(style: UIActivityIndicatorView.Style = .gray) -> UIActivityIndicatorView {
        let activityIndicator = UIActivityIndicatorView(style: style)
        return activityIndicator
    }
    
    open func dmr_dim(animated: Bool = true, color: UIColor = .black, alpha: CGFloat = 0.6, ratio: CGFloat = 1) {
        
        if let _ = self.dimmerView {
            
        } else {
            let dimmer = createDimmerView(color: color, alpha: alpha)
            if animated {
                fadeInSubview(dimmer)
            } else {
                addSubview(dimmer)
            }
            dimmer.snp.makeConstraints { $0.edges.equalToSuperview() }
            dimmerView = dimmer
        }
    }
    
    open func dmr_undim(animated: Bool = true) {
        if animated {
            dimmerView?.fadeOutFromSuperview(completion: {
                self.clearKVO()
            })
        } else {
            dimmerView?.removeFromSuperview()
            clearKVO()
        }
    }
    
    open var dmr_isLoading: Bool {
        if let _ = get(kDimmerActivityIndicatorView), dimmingRatio > 0 {
            return true
        } else {
            return false
        }
    }
    
    open func dmr_showLoading(animated: Bool = true, color: UIColor = UIColor(rgbHex: 0xEF4B49), dimColor: UIColor = .clear, alpha: CGFloat = 1, verticalRatio: CGFloat = 1, isBlock: Bool = true) {
        dmr_dim(animated: animated, color: dimColor, alpha: alpha)
        if let _ = self.dimmerActivityView {
            // already loading
        } else {
            let dimmerActivity = createDimmerActivityView()
            if animated {
                fadeInSubview(dimmerActivity)
            } else {
                addSubview(dimmerActivity)
            }
            dimmerActivity.snp.makeConstraints { (make) in
                make.centerX.equalToSuperview()
                make.centerY.equalToSuperview().multipliedBy(verticalRatio)
            }
            dimmerActivity.startAnimating()
            dimmerActivityView = dimmerActivity
        }
        dimmerView?.isUserInteractionEnabled = isBlock
    }
    
    open func dmr_hideLoading(animated: Bool = true) {
        dmr_undim(animated: animated)
    }
    
    fileprivate func clearKVO() {
        
        dimmerView?.removeFromSuperview()
        dimmerActivityView?.removeFromSuperview()
        
        set(nil, forKey: dimmerKey ?? kDimmerView)
        set(nil, forKey: kDimmerActivityIndicatorView)
        set(nil, forKey: kDimmerViewRatio)
    }
}

// MARK: - Gradient
extension UIView {
    
    private var kUIViewGradientLayer: String { return "kUIViewGradientLayer" }
    
    open func setGradient(_ direction: DimmerEffectDirection, start: CGFloat = 0, end: CGFloat = 1, startAlpha: CGFloat = 1, color: UIColor) {
        
        // 1. init common variables
        let effectLayer = CAGradientLayer()
        effectLayer.frame = bounds
        effectLayer.colors = [
            color.withAlphaComponent(startAlpha).cgColor,
            color.withAlphaComponent(0).cgColor
        ]
        
        // 2. set for each style
        switch direction {
        case .fromTop:
            effectLayer.startPoint = CGPoint(x: 0.5, y: start)
            effectLayer.endPoint = CGPoint(x: 0.5, y: end)
        case .fromLeft:
            effectLayer.startPoint = CGPoint(x: start, y: 0.5)
            effectLayer.endPoint = CGPoint(x: end, y: 0.5)
        case .fromBottom:
            effectLayer.startPoint = CGPoint(x: 0.5, y: 1 - start)
            effectLayer.endPoint = CGPoint(x: 0.5, y: 1 - end)
        case .fromRight:
            effectLayer.startPoint = CGPoint(x: 1 - start, y: 0.5)
            effectLayer.endPoint = CGPoint(x: 1 - end, y: 0.5)
        default:
            effectLayer.startPoint = CGPoint(x: 0.5, y: start)
            effectLayer.endPoint = CGPoint(x: 0.5, y: end)
        }
        
        // 3. check layer
        if let oldLayer = get(kUIViewGradientLayer) as? CAGradientLayer {
            oldLayer.removeFromSuperlayer()
        }
        layer.addSublayer(effectLayer)
        set(effectLayer, forKey: kUIViewGradientLayer)
    }
    
    open func removeGradient() {
        if let gradientLayer = get(kUIViewGradientLayer) as? CAGradientLayer {
            gradientLayer.removeFromSuperlayer()
            set(nil, forKey: kUIViewGradientLayer)
        }
    }
}
