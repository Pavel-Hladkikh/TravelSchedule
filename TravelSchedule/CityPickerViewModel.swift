import Foundation
import Combine

@MainActor
final class CityPickerViewModel: ObservableObject {

    @Published var query: String = ""
    @Published private(set) var state: LoadingState = .loading
    @Published private(set) var filteredCities: [String] = []

    private var allCities: [String] = []
    private var cancellables = Set<AnyCancellable>()
    private let allStationsService: AllStationsServiceProtocol

    private var loadTask: Task<Void, Never>?
    private var retryTimer: Timer?
    private var retryCount = 0

    init(allStationsService: AllStationsServiceProtocol) {
        self.allStationsService = allStationsService

        $query
            .debounce(for: .milliseconds(150), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.applyFilter()
            }
            .store(in: &cancellables)
    }

    deinit {
        loadTask?.cancel()
        retryTimer?.invalidate()
    }

    func load() async {
        loadTask?.cancel()
        stopRetryTimer()

        loadTask = Task {
            state = .loading
            filteredCities = []

            do {
                let response = try await allStationsService.getAllStations(
                    lang: "ru_RU",
                    format: "json"
                )

                guard !Task.isCancelled else { return }

                let cities = extractRussianCities(from: response)
                allCities = Array(Set(cities)).sorted()

                if allCities.isEmpty {
                    filteredCities = []
                    state = .empty("Города не найдены")
                } else {
                    filteredCities = allCities
                    state = .loaded
                }

                retryCount = 0
            } catch {
                guard !Task.isCancelled else { return }

                allCities = []
                filteredCities = []

                if error.isNoInternet {
                    state = .noInternet
                    startRetryTimer()
                } else {
                    state = .error("Ошибка загрузки")
                }
            }
        }

        await loadTask?.value
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

        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)

        if q.isEmpty {
            filteredCities = allCities
            state = .loaded
            return
        }

        let result = allCities.filter {
            $0.localizedCaseInsensitiveContains(q)
        }

        filteredCities = result
        state = result.isEmpty ? .empty("Город не найден") : .loaded
    }

    private func startRetryTimer() {
        stopRetryTimer()

        let delay = min(pow(2.0, Double(retryCount)), 10.0)
        retryCount += 1

        retryTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            guard let self else { return }

            Task { @MainActor in
                if self.state == .noInternet {
                    await self.load()
                } else {
                    self.stopRetryTimer()
                }
            }
        }
    }

    private func stopRetryTimer() {
        retryTimer?.invalidate()
        retryTimer = nil
    }

    private func extractRussianCities(from response: AllStationsResponse) -> [String] {
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
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
