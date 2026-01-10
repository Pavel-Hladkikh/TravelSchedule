import SwiftUI

struct ErrorView: View {
    let image: String
    let title: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(image)
                .resizable()
                .scaledToFit()
                .frame(width: 223, height: 223)
            
            Text(title)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 160)
        .padding(.horizontal, 24)
    }
}
