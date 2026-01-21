import SwiftUI

struct RootView: View {
    @StateObject private var vm = RootViewModel()
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            Group {
                if vm.showSplash {
                    SplashView()
                } else {
                    TabView {
                        MainSearchView()
                            .tabItem {
                                Image("tab_main")
                                    .renderingMode(.template)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 30, height: 30)
                            }
                        
                        SettingsView()
                            .tabItem {
                                Image("setting")
                                    .renderingMode(.template)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 30, height: 30)
                            }
                    }
                    .tint(AppColors.tabTint)
                    .overlay(alignment: .bottom) {
                        if colorScheme == .light {
                            Rectangle()
                                .fill(Color.gray.opacity(0.35))
                                .frame(height: 1)
                                .padding(.bottom, 49)
                        }
                    }
                }
            }
        }
        .task {
            await vm.startSplashIfNeeded()
        }
    }
}

#Preview {
    RootView()
}
