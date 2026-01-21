import UIKit

@MainActor
enum ThemeService {
    
    private static let key = "isDarkTheme"
    
    static func apply(isDark: Bool) {
        UserDefaults.standard.set(isDark, forKey: key)
        
        guard
            let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        else { return }
        
        scene.windows.forEach { window in
            window.overrideUserInterfaceStyle = isDark ? .dark : .light
        }
    }
    
    static func isDark() -> Bool {
        UserDefaults.standard.bool(forKey: key)
    }
}
