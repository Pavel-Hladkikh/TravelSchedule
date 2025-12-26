import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            Image("splash")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        }
    }
}

#Preview {
    SplashView()
}
