import SwiftUI

struct SettingsView: View {
    
    @StateObject private var vm = SettingsViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            
            Color.clear
                .frame(height: 24)
            
            themeRow
            agreementRow
            
            Spacer(minLength: 0)
            
            footer
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
        }
        .background(AppColors.background)
        .fullScreenCover(isPresented: $vm.showAgreement) {
            UserAgreementView()
        }
        .onAppear {
            vm.onAppear()
        }
    }
    
    private var themeRow: some View {
        HStack {
            Text("Темная тема")
                .font(.system(size: 17, weight: .regular))
                .tracking(-0.41)
                .foregroundStyle(AppColors.textPrimary)
            
            Spacer()
            
            Toggle("", isOn: $vm.isDark)
                .labelsHidden()
                .tint(AppColors.brandBlue)
        }
        .frame(height: 60)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
        .onChange(of: vm.isDark) { _, value in
            vm.setDark(value)
        }
    }
    
    private var agreementRow: some View {
        Button {
            vm.openAgreement()
        } label: {
            HStack {
                Text("Пользовательское соглашение")
                    .font(.system(size: 17, weight: .regular))
                    .tracking(-0.41)
                    .foregroundStyle(AppColors.textPrimary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 24, weight: .regular))
                    .frame(width: 24, height: 24)
                    .foregroundStyle(AppColors.textPrimary)
                
            }
            .frame(height: 60)
            .padding(.horizontal, 16)
        }
        .buttonStyle(.plain)
    }
    
    private var footer: some View {
        VStack(spacing: 16) {
            Text("Приложение использует API «Яндекс.Расписания»")
                .font(.system(size: 12, weight: .regular))
                .tracking(0.4)
                .foregroundStyle(AppColors.textPrimary)
                .multilineTextAlignment(.center)
            
            Text("Версия 1.0 (beta)")
                .font(.system(size: 12, weight: .regular))
                .tracking(0.4)
                .foregroundStyle(AppColors.textPrimary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}
