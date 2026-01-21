import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var isDark: Bool = ThemeService.isDark()
    @Published var showAgreement: Bool = false

    func onAppear() {
        isDark = ThemeService.isDark()
    }

    func setDark(_ value: Bool) {
        ThemeService.apply(isDark: value)
    }

    func openAgreement() {
        showAgreement = true
    }
}
