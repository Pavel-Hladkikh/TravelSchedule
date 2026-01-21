import Foundation
import Combine

@MainActor
final class StationPickerViewModel: ObservableObject {
    
    struct StationItem: Identifiable, Hashable, Sendable {
        let id: String
        let title: String
        let code: String
    }
    
    @Published var query: String = ""
    @Published private(set) var state: LoadingState = .loading
    @Published private(set) var filteredStations: [StationItem] = []
    
    private var allStations: [StationItem] = []
    private var cancellables = Set<AnyCancellable>()
    
    private let cityTitle: String
    private let apiClient: RaspAPIClient
    
    init(cityTitle: String, apiClient: RaspAPIClient) {
        self.cityTitle = cityTitle
        self.apiClient = apiClient
        
        $query
            .debounce(for: .milliseconds(150), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.applyFilter()
            }
            .store(in: &cancellables)
    }
    
    func load() async {
        state = .loading
        filteredStations = []
        
        var retryCount = 0
        
        while !Task.isCancelled {
            do {
                let response = try await apiClient.allStations(lang: "ru_RU", format: "json")
                if Task.isCancelled { return }
                
                allStations = extractStationsForCity(from: response, cityTitle: cityTitle)
                
                if allStations.isEmpty {
                    state = .empty("Станции не найдены")
                    filteredStations = []
                } else {
                    state = .loaded
                    applyFilter()
                }
                return
                
            } catch {
                if Task.isCancelled { return }
                
                if error.isNoInternet {
                    state = .noInternet
                    let delaySec = min(pow(2.0, Double(retryCount)), 10.0)
                    retryCount += 1
                    let ns = UInt64(delaySec * 1_000_000_000)
                    try? await Task.sleep(nanoseconds: ns)
                    continue
                } else {
                    state = .error("Не удалось загрузить список станций")
                    filteredStations = []
                    return
                }
            }
        }
    }
    
    private func applyFilter() {
        switch state {
        case .loading, .noInternet, .error:
            return
        case .loaded, .empty, .idle:
            break
        }
        
        let q = query.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
        if q.isEmpty {
            filteredStations = allStations
            state = allStations.isEmpty ? .empty("Станции не найдены") : .loaded
            return
        }
        
        let result = allStations.filter { $0.title.localizedCaseInsensitiveContains(q) }
        filteredStations = result
        state = result.isEmpty ? .empty("Станция не найдена") : .loaded
    }
    
    private func extractStationsForCity(
        from response: Components.Schemas.AllStationsResponse,
        cityTitle: String
    ) -> [StationItem] {
        let countries = response.countries ?? []
        let russia = countries.first { ($0.title ?? "") == "Россия" }
        let regions = russia?.regions ?? []
        let settlements = regions.flatMap { $0.settlements ?? [] }
        let city = settlements.first { ($0.title ?? "") == cityTitle }
        let stations = city?.stations ?? []
        
        let mapped: [StationItem] = stations.compactMap { station in
            let code = (station.codes?.yandex_code ?? station.code ?? "")
                .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            
            let rawTitle = station.popular_title ?? station.title ?? station.short_title ?? ""
            let title = rawTitle.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            
            guard !code.isEmpty, !title.isEmpty else { return nil }
            if title.hasPrefix("#") { return nil }
            
            return StationItem(id: code, title: title, code: code)
        }
        
        return Array(Set(mapped)).sorted { $0.title < $1.title }
    }
}
