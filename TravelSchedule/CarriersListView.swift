import SwiftUI
import OpenAPIURLSession

private let raspBaseURL = URL(string: "https://api.rasp.yandex-net.ru")!

struct CarriersListView: View {

    @Environment(\.dismiss) private var dismiss

    private let fromTitle: String
    private let toTitle: String

    @StateObject private var vm: CarriersListViewModel

    @State private var isFiltersPresented = false
    @State private var filtersApplied = false

    @State private var timeSelection: Set<DepartureInterval> = []
    @State private var showTransfers: Bool? = nil

    @State private var isCarrierInfoPresented = false

    init(
        fromTitle: String,
        toTitle: String,
        fromCode: String,
        toCode: String,
        apiKey: String
    ) {
        self.fromTitle = fromTitle
        self.toTitle = toTitle

        let client = Client(
            serverURL: raspBaseURL,
            transport: URLSessionTransport()
        )
        let service = SearchService(client: client, apikey: apiKey)

        _vm = StateObject(
            wrappedValue: CarriersListViewModel(
                searchService: service,
                fromCode: fromCode,
                toCode: toCode
            )
        )
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {

                VStack(spacing: 0) {

                    Text("\(fromTitle) → \(toTitle)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 16)
                        .padding(.horizontal, 16)

                    StateContentView(
                        state: vm.state,
                        emptyMessage: "Вариантов нет"
                    ) {
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(vm.rows) { row in
                                    Button {
                                        isCarrierInfoPresented = true
                                    } label: {
                                        carrierCard(row)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                        .padding(.bottom, 53)
                    }
                    .padding(.top, 16)
                }
                .background(AppColors.background)

                bottomButton
            }
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .top, spacing: 0) { topBar }
            .task { await vm.load() }
        }
        .fullScreenCover(isPresented: $isFiltersPresented) {
            FiltersView(
                timeSelection: timeSelection,
                showTransfers: showTransfers,
                onApply: { newTimeSelection, newShowTransfers in
                    timeSelection = newTimeSelection
                    showTransfers = newShowTransfers
                    filtersApplied = true
                    vm.applyFilters(
                        timeSelection: newTimeSelection,
                        showTransfers: newShowTransfers
                    )
                }
            )
        }
        .fullScreenCover(isPresented: $isCarrierInfoPresented) {
            CarrierInfo()
        }
    }

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(AppColors.textPrimary)
                    .frame(width: 44, height: 44)
            }
            Spacer()
        }
        .padding(.horizontal, 6)
        .background(AppColors.background)
    }

    private var bottomButton: some View {
        VStack {
            Button { isFiltersPresented = true } label: {
                HStack(spacing: 4) {
                    Text("Уточнить время")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)

                    if filtersApplied {
                        Circle()
                            .fill(AppColors.indicatorRed)
                            .frame(width: 8, height: 8)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(AppColors.brandBlue)
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 58)
        }
    }

    private func carrierCard(_ row: CarriersListViewModel.CarrierRow) -> some View {
        let cardText = Color(red: 26/255, green: 27/255, blue: 34/255)

        return ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(AppColors.cardGray)

            VStack(alignment: .leading, spacing: 0) {

                HStack(alignment: .top, spacing: 8) {

                    logoView(row.logoURL)
                        .frame(width: 38, height: 38)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.top, 14)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(row.title)
                            .font(.system(size: 17))
                            .foregroundStyle(cardText)

                        if let subtitle = row.subtitle, !subtitle.isEmpty {
                            Text(subtitle)
                                .font(.system(size: 12))
                                .kerning(0.4)
                                .foregroundStyle(AppColors.subtitleRed)
                        }
                    }
                    .padding(.top, 14)

                    Spacer()

                    if let date = row.dateText {
                        Text(date)
                            .font(.system(size: 12))
                            .foregroundStyle(cardText)
                            .padding(.top, 14)
                            .padding(.trailing, 7)
                    }
                }
                .padding(.horizontal, 16)

                Spacer().frame(height: 18)

                HStack(spacing: 12) {
                    Text(row.departText ?? "--:--")
                        .font(.system(size: 17))
                        .foregroundStyle(cardText)

                    Rectangle()
                        .fill(AppColors.lineGray)
                        .frame(height: 1)

                    Text(row.durationText ?? "")
                        .font(.system(size: 12))
                        .foregroundStyle(cardText)
                        .lineLimit(1)

                    Rectangle()
                        .fill(AppColors.lineGray)
                        .frame(height: 1)

                    Text(row.arriveText ?? "--:--")
                        .font(.system(size: 17))
                        .foregroundStyle(cardText)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
            }
        }
        .frame(height: 104)
    }

    @ViewBuilder
    private func logoView(_ url: URL?) -> some View {
        if let url {
            AsyncImage(url: url) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Color.white.opacity(0.6)
            }
        } else {
            Color.white.opacity(0.6)
        }
    }
}
