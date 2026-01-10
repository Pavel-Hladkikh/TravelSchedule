import SwiftUI

struct SettingsView: View {
    
    @State private var isDark = ThemeService.isDark()
    @State private var showAgreement = false
    
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
        .fullScreenCover(isPresented: $showAgreement) {
            UserAgreementView()
        }
        .onAppear {
            isDark = ThemeService.isDark()
        }
    }
    
    private var themeRow: some View {
        HStack {
            Text("Темная тема")
                .font(.system(size: 17, weight: .regular))
                .tracking(-0.41)
                .foregroundStyle(AppColors.textPrimary)
            
            Spacer()
            
            Toggle("", isOn: $isDark)
                .labelsHidden()
                .tint(AppColors.brandBlue)
        }
        .frame(height: 60)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
        .onChange(of: isDark) { _, value in
            ThemeService.apply(isDark: value)
        }
    }
    
    private var agreementRow: some View {
        Button {
            showAgreement = true
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
