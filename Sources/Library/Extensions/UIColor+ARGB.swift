//
//  UIColor+ARGB.swift
//  Pods
//
//  Created by DragonCherry on 6/30/16.
//
//

import UIKit

extension UIColor {
    
    open var RGBString: String {
        let colorRef = cgColor.components
        let r: CGFloat = colorRef![0]
        let g: CGFloat = colorRef![1]
        let b: CGFloat = colorRef![2]
        return String(NSString(format: "%02lX%02lX%02lX", lroundf(Float(r * 255)), lroundf(Float(g * 255)), lroundf(Float(b * 255))))
    }
    
    open var ARGBString: String {
        let colorRef = cgColor.components
        let a: CGFloat = cgColor.alpha
        let r: CGFloat = colorRef![0]
        let g: CGFloat = colorRef![1]
        let b: CGFloat = colorRef![2]
        return String(NSString(format: "%02lX%02lX%02lX%02lX", lroundf(Float(a * 255)), lroundf(Float(r * 255)), lroundf(Float(g * 255)), lroundf(Float(b * 255))))
    }
    
    public convenience init(alpha: Float, red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        assert(alpha >= 0 || alpha <= 1, "Invalid alpha component")
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: CGFloat(alpha))
    }
    
    public convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    public convenience init(rgbHex: Int) {
        self.init(
            red: (rgbHex >> 16) & 0xff,
            green: (rgbHex >> 8) & 0xff,
            blue: rgbHex & 0xff)
    }
    
    convenience init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt32()
        Scanner(string: hex).scanHexInt32(&int)
        let a, r, g, b: UInt32
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (0, 0, 0, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
    
    public convenience init(rgbHex: Int, alpha: Float) {
        self.init(
            red: CGFloat((rgbHex >> 16) & 0xff),
            green: CGFloat((rgbHex >> 8) & 0xff),
            blue: CGFloat(rgbHex & 0xff),
            alpha: CGFloat(alpha) / 255.0)
    }
    
    public convenience init(argbHex: UInt32) {
        let alpha: UInt32 = (argbHex >> 24)
        self.init(
            red: CGFloat((argbHex >> 16) & 0xff),
            green: CGFloat((argbHex >> 8) & 0xff),
            blue: CGFloat(argbHex & 0xff),
            alpha: CGFloat(alpha) / 255.0)
    }
    
    @objc static func image(from color: UIColor) -> UIImage? {
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        context!.setFillColor(color.cgColor)
        context!.fill(rect)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img
    }
}

extension UIColor {
    func image() -> UIImage? {
        
        var colorImage: UIImage? = nil
        
        UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
        if let context = UIGraphicsGetCurrentContext() {
            context.setFillColor(self.cgColor)
            context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
            
            colorImage = UIGraphicsGetImageFromCurrentImageContext()
        }
        UIGraphicsEndImageContext()
        
        return colorImage
    }
}
