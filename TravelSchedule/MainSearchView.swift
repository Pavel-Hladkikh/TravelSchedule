import SwiftUI
import OpenAPIRuntime
import OpenAPIURLSession

private let apiKey = "7828af98-e2dc-45df-95f7-12b6d39376ef"
private let raspBaseURL = URL(string: "https://api.rasp.yandex-net.ru")!

struct MainSearchView: View {

    @StateObject private var vm = MainSearchViewModel()

    @State private var activeTarget: Target? = nil
    @State private var showCityPicker = false
    @State private var showStationPicker = false
    @State private var selectedCityTitle: String = ""
    @State private var showCarriers = false

    enum Target {
        case from
        case to
    }

    var body: some View {
        VStack(spacing: 16) {

            RouteCard(
                fromText: vm.fromText,
                toText: vm.toText,
                onTapFrom: { openCityPicker(target: .from) },
                onTapTo: { openCityPicker(target: .to) },
                onSwap: { vm.swapStations() }
            )
            .padding(.horizontal, 16)
            .padding(.top, 208)

            if vm.canSearch {
                Button {
                    showCarriers = true
                } label: {
                    Text("Найти")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(height: 60)
                        .frame(maxWidth: .infinity)
                        .background(AppColors.brandBlue)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                }
                .padding(.horizontal, 96)
                .padding(.top, 16)
            }

            Spacer(minLength: 0)
        }
        .background(AppColors.background)
        .fullScreenCover(isPresented: $showCityPicker) {
            CityPickerView { city in
                selectedCityTitle = city
                showCityPicker = false

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    showStationPicker = true
                }
            }
        }
        .fullScreenCover(isPresented: $showStationPicker) {
            StationPickerView(
                cityTitle: selectedCityTitle,
                allStationsService: makeAllStationsService()
            ) { item in
                applyStationSelection(
                    stationTitle: item.title,
                    stationCode: item.code
                )
                showStationPicker = false
            }
        }
        .fullScreenCover(isPresented: $showCarriers) {
            CarriersListView(
                fromTitle: vm.fromText,
                toTitle: vm.toText,
                fromCode: vm.fromCode,
                toCode: vm.toCode,
                apiKey: apiKey
            )
        }
    }

    private func openCityPicker(target: Target) {
        activeTarget = target
        showCityPicker = true
    }

    private func applyStationSelection(stationTitle: String, stationCode: String) {
        guard let target = activeTarget else { return }

        switch target {
        case .from:
            vm.setFrom(
                stationTitle: stationTitle,
                stationCode: stationCode,
                cityTitle: selectedCityTitle
            )
        case .to:
            vm.setTo(
                stationTitle: stationTitle,
                stationCode: stationCode,
                cityTitle: selectedCityTitle
            )
        }
    }

    private func makeAllStationsService() -> AllStationsServiceProtocol {
        let client = Client(
            serverURL: raspBaseURL,
            transport: URLSessionTransport()
        )
        return AllStationsService(client: client, apikey: apiKey)
    }
}

private struct RouteCard: View {

    let fromText: String
    let toText: String
    let onTapFrom: () -> Void
    let onTapTo: () -> Void
    let onSwap: () -> Void

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22)
                .fill(AppColors.brandBlue)

            HStack(spacing: 12) {

                VStack(spacing: 0) {

                    Button(action: onTapFrom) {
                        HStack {
                            Text(fromText.isEmpty ? "Откуда" : fromText)
                                .font(.system(size: 17))
                                .foregroundStyle(fromText.isEmpty ? .gray : .black)
                                .lineLimit(1)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .frame(height: 56)
                    }

                    Button(action: onTapTo) {
                        HStack {
                            Text(toText.isEmpty ? "Куда" : toText)
                                .font(.system(size: 17))
                                .foregroundStyle(toText.isEmpty ? .gray : .black)
                                .lineLimit(1)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .frame(height: 56)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.white)
                )
                .padding(.leading, 16)
                .padding(.vertical, 16)

                Button(action: onSwap) {
                    Image("swap_icon")
                        .resizable()
                        .scaledToFit()
                        .padding(10)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Color.white))
                }
                .padding(.trailing, 16)
            }
        }
        .frame(height: 128)
    }
}

#Preview {
    MainSearchView()
}
