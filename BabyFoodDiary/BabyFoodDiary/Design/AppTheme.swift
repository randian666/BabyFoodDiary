import SwiftUI
import UIKit

enum AppTheme {
    static let backgroundHex = "FFF8F2"
    static let primaryHex = "FF7A3D"
    static let background = adaptive(
        light: UIColor(red: 1, green: 0.973, blue: 0.949, alpha: 1),
        dark: UIColor(red: 0.075, green: 0.055, blue: 0.045, alpha: 1)
    )
    static let surface = adaptive(
        light: .white,
        dark: UIColor(red: 0.135, green: 0.102, blue: 0.085, alpha: 1)
    )
    static let ink = adaptive(
        light: UIColor(red: 0.239, green: 0.141, blue: 0.090, alpha: 1),
        dark: UIColor(red: 0.97, green: 0.91, blue: 0.87, alpha: 1)
    )
    static let secondaryInk = adaptive(
        light: UIColor(red: 0.612, green: 0.471, blue: 0.376, alpha: 1),
        dark: UIColor(red: 0.78, green: 0.69, blue: 0.63, alpha: 1)
    )
    static let primary = Color(red: 1, green: 0.478, blue: 0.239)
    static let warmSurface = adaptive(
        light: UIColor(red: 1, green: 0.941, blue: 0.894, alpha: 1),
        dark: UIColor(red: 0.22, green: 0.16, blue: 0.13, alpha: 1)
    )
    static let success = Color(red: 0.18, green: 0.62, blue: 0.36)
    static let warning = Color(red: 0.91, green: 0.57, blue: 0.08)
    static let danger = Color(red: 0.91, green: 0.31, blue: 0.36)
    static let cardCornerRadius: CGFloat = 22

    private static func adaptive(light: UIColor, dark: UIColor) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }
}
