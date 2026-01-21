import SwiftUI
import UIKit

enum AppColors {
    
    static var background: Color { dynamic(lightHex: 0xFFFFFF, darkHex: 0x1A1B22) }
    static var textPrimary: Color { dynamic(lightHex: 0x1A1B22, darkHex: 0xFFFFFF) }
    static var tabTint: Color { dynamic(lightHex: 0x000000, darkHex: 0xFFFFFF) }
    
    static let brandBlue = Color(hex: 0x3772E7)
    
    static let cardGray = Color(hex: 0xEEEEEE)
    static let lineGray = Color(hex: 0xAEB0B4)
    
    static let subtitleRed = Color(hex: 0xF56B6C)
    static let indicatorRed = Color(hex: 0xF56B6C)
    
    static var searchFieldBackground: Color {
        dynamic(lightHex: 0xEEEEEE, darkHex: 0x767680, darkAlpha: 0.24)
    }
    
    static var searchPlaceholder: Color {
        Color(uiColor: UIColor { tc in
            tc.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.60)
            : UIColor(hex: 0xAEB0B4)
        })
    }
    
    static func magnifierColor(isActive: Bool) -> Color {
        Color(uiColor: UIColor { tc in
            if tc.userInterfaceStyle == .dark {
                return isActive ? .white : UIColor(hex: 0xAEAFB4)
            } else {
                return isActive ? UIColor(hex: 0x1A1B22) : UIColor(hex: 0x3C3C43, alpha: 0.60)
            }
        })
    }
    
    static let clearIcon = Color(hex: 0xAEAFB4)
    
    private static func dynamic(lightHex: Int, darkHex: Int, darkAlpha: Double = 1) -> Color {
        Color(uiColor: UIColor { tc in
            if tc.userInterfaceStyle == .dark {
                return UIColor(hex: darkHex, alpha: darkAlpha)
            } else {
                return UIColor(hex: lightHex)
            }
        })
    }
}

private extension UIColor {
    convenience init(hex: Int, alpha: Double = 1) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(red: r, green: g, blue: b, alpha: alpha)
    }
}

private extension Color {
    init(hex: Int, alpha: Double = 1) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}
