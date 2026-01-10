import SwiftUI

@main
struct TravelScheduleApp: App {

    var body: some Scene {
        WindowGroup {
            RootView()
                .onAppear {
                    ThemeService.apply(isDark: ThemeService.isDark())
                }
        }
    }
}
