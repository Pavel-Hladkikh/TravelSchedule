import SwiftUI

struct UserAgreementView: View {
    
    @StateObject private var vm = UserAgreementViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            
            Color.clear
                .frame(height: 11)
            
            header
            
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    
                    Color.clear
                        .frame(height: 18)
                    
                    content
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            
        }
        .background(AppColors.background)
        .ignoresSafeArea(edges: .bottom)
    }
    
    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .resizable()
                    .frame(width: 17, height: 22)
                    .foregroundStyle(AppColors.textPrimary)
            }
            
            Spacer()
            
            Text(vm.headerTitle)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)
            
            Spacer()
            
            Color.clear
                .frame(width: 24, height: 24)
        }
        .padding(.horizontal, 16)
        .frame(height: 44)
    }
    
    private var content: some View {
        VStack(alignment: .leading, spacing: 18) {
            
            Text(vm.docTitle)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)
            
            formattedText
        }
    }
    
    private var formattedText: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(vm.lines.indices, id: \.self) { index in
                let line = vm.lines[index].trimmingCharacters(in: .whitespaces)
                
                if line.isEmpty {
                    Color.clear.frame(height: 8)
                } else if vm.isSectionTitle(line) {
                    Text(line)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)
                        .padding(.top, 12)
                } else {
                    Text(line)
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(AppColors.textPrimary)
                }
            }
        }
    }
}
