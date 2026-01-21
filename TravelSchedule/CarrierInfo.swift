import SwiftUI
import UIKit

struct CarrierInfo: View {
    
    @Environment(\.dismiss) private var dismiss
    
    let row: CarriersListViewModel.CarrierRow
    @StateObject private var vm: CarrierInfoViewModel
    
    init(
        row: CarriersListViewModel.CarrierRow,
        apiClient: RaspAPIClient = RaspAPI.shared
    ) {
        self.row = row
        
        let seed = CarrierInfoViewModel.DataModel(
            title: row.title,
            logoURL: row.logoURL,
            email: row.email,
            phone: row.phone,
            website: row.website
        )
        
        _vm = StateObject(
            wrappedValue: CarrierInfoViewModel(
                seed: seed,
                carrierCode: row.carrierCode,
                apiClient: apiClient
            )
        )
    }
    
    var body: some View {
        VStack(spacing: 0) {
            
            Color.clear
                .frame(height: 11)
            
            header
            
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    
                    Color.clear
                        .frame(height: 29)
                    
                    logoBlock
                    
                    Color.clear
                        .frame(height: 16)
                    
                    Text(vm.data.title)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)
                        .padding(.horizontal, 16)
                    
                    Color.clear
                        .frame(height: 16)
                    
                    infoRowEmail(title: "E-mail", value: vm.data.email)
                    
                    infoRowPhone(title: "Телефон", value: vm.data.phone)
                }
            }
        }
        .background(AppColors.background)
        .ignoresSafeArea(edges: .bottom)
        .task { await vm.load() }
    }
    
    private var header: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(AppColors.textPrimary)
                    .frame(width: 44, height: 44)
            }
            
            Spacer()
            
            Text("Информация о перевозчике")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)
            
            Spacer()
            
            Color.clear
                .frame(width: 24, height: 24)
        }
        .frame(height: 44)
    }
    
    private var logoBlock: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
            
            logoView(vm.data.logoURL)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
        }
        .frame(height: 104)
        .padding(.horizontal, 16)
    }
    
    private func infoRowEmail(title: String, value: String?) -> some View {
        rowBase(title: title, value: value, onTap: {
            let recipients = parseEmails(value)
            guard let first = recipients.first else { return }
            
            if let url = URL(string: "mailto:\(first)") {
                UIApplication.shared.open(url)
            }
        })
    }
    
    private func infoRowPhone(title: String, value: String?) -> some View {
        rowBase(title: title, value: value, onTap: {
            guard let raw = value?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines),
                  !raw.isEmpty else { return }
            
            let digits = raw.filter { $0.isNumber || $0 == "+" }
            guard !digits.isEmpty else { return }
            
            if let url = URL(string: "tel:\(digits)") {
                UIApplication.shared.open(url)
            }
        })
    }
    
    private func rowBase(title: String, value: String?, onTap: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 17, weight: .regular))
                .tracking(-0.41)
                .foregroundStyle(AppColors.textPrimary)
            
            if let v = value, !v.isEmpty {
                Button(action: onTap) {
                    Text(v)
                        .font(.system(size: 12, weight: .regular))
                        .kerning(0.4)
                        .foregroundStyle(AppColors.brandBlue)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            } else {
                Text("Нет данных")
                    .font(.system(size: 12, weight: .regular))
                    .kerning(0.4)
                    .foregroundStyle(AppColors.textPrimary)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 60, alignment: .center)
    }
    
    private func parseEmails(_ value: String?) -> [String] {
        guard var raw = value?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines),
              !raw.isEmpty else { return [] }
        
        if raw.lowercased().hasPrefix("mailto:") {
            raw = String(raw.dropFirst("mailto:".count))
        }
        
        return raw
            .split { $0 == "," || $0 == ";" || $0.isNewline }
            .map { $0.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0.contains("@") }
    }
    
    @ViewBuilder
    private func logoView(_ url: URL?) -> some View {
        if let url {
            AsyncImage(url: url) { image in
                image.resizable().scaledToFit()
            } placeholder: {
                Color.black.opacity(0.06)
            }
        } else {
            Color.black.opacity(0.06)
        }
    }
}
