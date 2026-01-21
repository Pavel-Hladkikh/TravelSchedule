import SwiftUI

struct StationPickerView: View {
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm: StationPickerViewModel
    
    private let onSelect: @MainActor (StationPickerViewModel.StationItem) -> Void
    
    init(
        cityTitle: String,
        apiClient: RaspAPIClient,
        onSelect: @escaping @MainActor (StationPickerViewModel.StationItem) -> Void
    ) {
        _vm = StateObject(
            wrappedValue: StationPickerViewModel(
                cityTitle: cityTitle,
                apiClient: apiClient
            )
        )
        self.onSelect = onSelect
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchField
                    .padding(.horizontal, 16)
                    .padding(.top, 2)
                
                StateContentView(
                    state: vm.state,
                    emptyMessage: "Станция не найдена"
                ) {
                    List {
                        ForEach(vm.filteredStations) { station in
                            Button {
                                onSelect(station)
                                dismiss()
                            } label: {
                                HStack {
                                    Text(station.title)
                                        .font(.system(size: 17, weight: .regular))
                                        .tracking(-0.41)
                                        .foregroundStyle(AppColors.textPrimary)
                                        .lineLimit(1)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(AppColors.textPrimary)
                                }
                                .frame(height: 60)
                                .contentShape(Rectangle())
                            }
                            .listRowSeparator(.hidden)
                            .listRowInsets(
                                EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
                            )
                            .listRowBackground(AppColors.background)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(AppColors.background)
                }
                .padding(.top, 16)
                
                Spacer(minLength: 0)
            }
            .background(AppColors.background)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Выбор станции")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(AppColors.textPrimary)
                    }
                }
            }
            .task { await vm.load() }
        }
    }
    
    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AppColors.magnifierColor(isActive: !vm.query.isEmpty))
            
            TextField(
                "",
                text: $vm.query,
                prompt: Text("Введите запрос")
                    .foregroundStyle(AppColors.searchPlaceholder)
            )
            .font(.system(size: 17, weight: .regular))
            .tracking(-0.41)
            .foregroundStyle(AppColors.textPrimary)
            
            if !vm.query.isEmpty {
                Button { vm.query = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(AppColors.clearIcon)
                }
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 36)
        .background(AppColors.searchFieldBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}
