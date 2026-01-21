import Foundation

@MainActor
final class RootViewModel: ObservableObject {
    @Published var showSplash: Bool = true
    
    func startSplashIfNeeded() async {
        guard showSplash else { return }
        try? await Task.sleep(nanoseconds: 1_200_000_000)
        showSplash = false
    }
}
