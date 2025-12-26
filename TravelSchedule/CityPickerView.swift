import SwiftUI
import OpenAPIURLSession

private let apiKey = "7828af98-e2dc-45df-95f7-12b6d39376ef"

struct CityPickerView: View {

    let onSelect: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm: CityPickerViewModel

    init(onSelect: @escaping (String) -> Void) {
        self.onSelect = onSelect

        let client = Client(
            serverURL: URL(string: "https://api.rasp.yandex-net.ru")!,
            transport: URLSessionTransport()
        )

        let service = AllStationsService(client: client, apikey: apiKey)
        _vm = StateObject(wrappedValue: CityPickerViewModel(allStationsService: service))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                searchField
                    .padding(.horizontal, 16)
                    .padding(.top, 2)

                StateContentView(
                    state: vm.state,
                    emptyMessage: "Город не найден"
                ) {
                    List(vm.filteredCities, id: \.self) { city in
                        Button {
                            onSelect(city)
                            dismiss()
                        } label: {
                            HStack {
                                Text(city)
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
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(AppColors.background)
                }
                .padding(.top, 16)

                Spacer(minLength: 0)
            }
            .background(AppColors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Выбор города")
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
        .task { await vm.load() }
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
            .textInputAutocapitalization(.sentences)
            .autocorrectionDisabled()

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
