import Foundation
import Combine

@MainActor
final class CityPickerViewModel: ObservableObject {
    
    @Published var query: String = ""
    @Published private(set) var state: LoadingState = .loading
    @Published private(set) var filteredCities: [String] = []
    
    private var allCities: [String] = []
    private var cancellables = Set<AnyCancellable>()
    private let apiClient: RaspAPIClient
    
    init(apiClient: RaspAPIClient) {
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
        filteredCities = []
        
        var retryCount = 0
        
        while !Task.isCancelled {
            do {
                let response = try await apiClient.allStations(lang: "ru_RU", format: "json")
                if Task.isCancelled { return }
                
                let cities = extractRussianCities(from: response)
                allCities = Array(Set(cities)).sorted()
                
                if allCities.isEmpty {
                    filteredCities = []
                    state = .empty("Города не найдены")
                } else {
                    filteredCities = allCities
                    state = .loaded
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
                    allCities = []
                    filteredCities = []
                    state = .error("Ошибка загрузки")
                    return
                }
            }
        }
    }
    
    private func applyFilter() {
        switch state {
        case .loaded:
            break
        case .empty(let msg) where msg == "Город не найден":
            break
        default:
            return
        }
        
        let q = query.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
        if q.isEmpty {
            filteredCities = allCities
            state = .loaded
            return
        }
        
        let result = allCities.filter { $0.localizedCaseInsensitiveContains(q) }
        filteredCities = result
        state = result.isEmpty ? .empty("Город не найден") : .loaded
    }
    
    private func extractRussianCities(from response: Components.Schemas.AllStationsResponse) -> [String] {
        let countries = response.countries ?? []
        
        let russia =
        countries.first {
            let t = ($0.title ?? "").lowercased()
            return t == "россия" || t == "russia" || t == "russian federation"
        }
        ??
        countries.first {
            let t = ($0.title ?? "").lowercased()
            return t.contains("рос") || t.contains("russ")
        }
        
        let raw =
        russia?
            .regions?
            .flatMap { $0.settlements ?? [] }
            .compactMap { $0.title }
        ?? []
        
        return raw
            .map { $0.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
