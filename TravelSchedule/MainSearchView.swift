import SwiftUI

struct MainSearchView: View {
    
    @StateObject private var vm = MainSearchViewModel()
    
    @State private var activeTarget: Target? = nil
    @State private var showCityPicker = false
    @State private var showStationPicker = false
    @State private var selectedCityTitle: String = ""
    @State private var showCarriers = false
    
    @State private var pendingOpenStationPicker = false
    
    enum Target {
        case from
        case to
    }
    
    var body: some View {
        VStack(spacing: 16) {
            
            VStack(spacing: 0) {
                StoriesRowView()
                
                RouteCard(
                    fromText: vm.fromText,
                    toText: vm.toText,
                    onTapFrom: { openCityPicker(target: .from) },
                    onTapTo: { openCityPicker(target: .to) },
                    onSwap: { vm.swapStations() }
                )
                .padding(.horizontal, 16)
            }
            
            if vm.canSearch {
                Button {
                    showCarriers = true
                } label: {
                    Text("Найти")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 150, height: 60)
                        .background(AppColors.brandBlue)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                }
                .padding(.top, 16)
            }
            
            Spacer(minLength: 0)
        }
        .background(AppColors.background)
        .fullScreenCover(
            isPresented: $showCityPicker,
            onDismiss: {
                if pendingOpenStationPicker {
                    pendingOpenStationPicker = false
                    showStationPicker = true
                }
            },
            content: {
                CityPickerView(apiClient: RaspAPI.shared) { city in
                    selectedCityTitle = city
                    pendingOpenStationPicker = true
                    showCityPicker = false
                }
            }
        )
        .fullScreenCover(isPresented: $showStationPicker) {
            StationPickerView(
                cityTitle: selectedCityTitle,
                apiClient: RaspAPI.shared
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
                apiClient: RaspAPI.shared
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
