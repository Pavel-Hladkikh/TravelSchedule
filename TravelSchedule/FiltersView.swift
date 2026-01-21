import SwiftUI

enum DepartureInterval: CaseIterable, Hashable, Sendable {
    case morning
    case day
    case evening
    case night
    
    var title: String {
        switch self {
        case .morning: return "Утро 06:00 - 12:00"
        case .day: return "День 12:00 - 18:00"
        case .evening: return "Вечер 18:00 - 00:00"
        case .night: return "Ночь 00:00 - 06:00"
        }
    }
    
    var range: ClosedRange<Int> {
        switch self {
        case .morning: return 6 * 60 ... 11 * 60 + 59
        case .day: return 12 * 60 ... 17 * 60 + 59
        case .evening: return 18 * 60 ... 23 * 60 + 59
        case .night: return 0 ... 5 * 60 + 59
        }
    }
}

struct FiltersView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var timeSelection: Set<DepartureInterval>
    @State private var showTransfers: Bool?
    
    private let onApply: @MainActor (Set<DepartureInterval>, Bool?) -> Void
    
    init(
        timeSelection: Set<DepartureInterval>,
        showTransfers: Bool?,
        onApply: @escaping @MainActor (Set<DepartureInterval>, Bool?) -> Void
    ) {
        _timeSelection = State(initialValue: timeSelection)
        _showTransfers = State(initialValue: showTransfers)
        self.onApply = onApply
    }
    
    private var canApply: Bool {
        !timeSelection.isEmpty && showTransfers != nil
    }
    
    var body: some View {
        VStack(spacing: 0) {
            
            HStack(spacing: 0) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(AppColors.textPrimary)
                        .frame(width: 44, height: 44)
                }
                Spacer()
            }
            .padding(.horizontal, 6)
            .frame(maxWidth: .infinity)
            .background(AppColors.background)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    
                    Text("Время отправления")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)
                        .padding(.top, 8)
                    
                    VStack(spacing: 0) {
                        ForEach(DepartureInterval.allCases, id: \.self) { interval in
                            rowCheckbox(
                                title: interval.title,
                                isSelected: timeSelection.contains(interval)
                            ) {
                                toggleTimeSelection(interval)
                            }
                        }
                    }
                    .padding(.top, 16)
                    
                    Text("Показывать варианты с пересадками")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)
                        .padding(.top, 24)
                    
                    VStack(spacing: 0) {
                        rowRadio(title: "Да", isSelected: showTransfers == true) {
                            showTransfers = true
                        }
                        rowRadio(title: "Нет", isSelected: showTransfers == false) {
                            showTransfers = false
                        }
                    }
                    .padding(.top, 16)
                    
                    Color.clear.frame(height: 24)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
        }
        .background(AppColors.background)
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if canApply {
                Button {
                    onApply(timeSelection, showTransfers)
                    dismiss()
                } label: {
                    Text("Применить")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(AppColors.brandBlue)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
                .background(AppColors.background)
            } else {
                AppColors.background.frame(height: 24)
            }
        }
    }
    
    private func toggleTimeSelection(_ interval: DepartureInterval) {
        if timeSelection.contains(interval) {
            timeSelection.remove(interval)
        } else {
            timeSelection.insert(interval)
        }
    }
    
    private func rowCheckbox(title: String, isSelected: Bool, onTap: @escaping () -> Void) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(AppColors.textPrimary)
            
            Spacer()
            
            Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)
        }
        .frame(height: 60)
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
    }
    
    private func rowRadio(title: String, isSelected: Bool, onTap: @escaping () -> Void) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(AppColors.textPrimary)
            
            Spacer()
            
            Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)
        }
        .frame(height: 60)
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
    }
}
