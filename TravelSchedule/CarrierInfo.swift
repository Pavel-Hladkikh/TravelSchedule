import SwiftUI

struct CarrierInfo: View {

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            AppColors.background
                .ignoresSafeArea()
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("Информация о перевозчике")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(AppColors.textPrimary)
                    }

                    ToolbarItem(placement: .topBarLeading) {
                        Button { dismiss() } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(AppColors.textPrimary)
                        }
                    }
                }
        }
    }
}
