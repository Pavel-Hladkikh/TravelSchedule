import Foundation
import Combine

@MainActor
final class StationPickerViewModel: ObservableObject {

    struct StationItem: Identifiable, Hashable {
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
    private let allStationsService: AllStationsServiceProtocol

    private var loadTask: Task<Void, Never>?
    private var retryTimer: Timer?
    private var retryCount = 0

    init(cityTitle: String, allStationsService: AllStationsServiceProtocol) {
        self.cityTitle = cityTitle
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

            do {
                let response = try await allStationsService.getAllStations(
                    lang: "ru_RU",
                    format: "json"
                )

                guard !Task.isCancelled else { return }

                let stations = extractStationsForCity(
                    from: response,
                    cityTitle: cityTitle
                )
                allStations = stations

                if allStations.isEmpty {
                    state = .empty("Станции не найдены")
                    filteredStations = []
                } else {
                    state = .loaded
                    retryCount = 0
                    applyFilter()
                }
            } catch {
                guard !Task.isCancelled else { return }

                if error.isNoInternet {
                    state = .noInternet
                    startRetryTimer()
                } else {
                    state = .error("Не удалось загрузить список станций")
                }
                filteredStations = []
            }
        }

        await loadTask?.value
    }

    private func startRetryTimer() {
        stopRetryTimer()

        let delay = min(pow(2.0, Double(retryCount)), 10.0)
        retryCount += 1

        retryTimer = Timer.scheduledTimer(
            withTimeInterval: delay,
            repeats: false
        ) { [weak self] _ in
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

    private func applyFilter() {
        switch state {
        case .loading, .noInternet, .error:
            return
        case .loaded, .empty, .idle:
            break
        }

        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)

        if q.isEmpty {
            filteredStations = allStations
            state = allStations.isEmpty
                ? .empty("Станции не найдены")
                : .loaded
            return
        }

        let result = allStations.filter {
            $0.title.localizedCaseInsensitiveContains(q)
        }

        filteredStations = result
        state = result.isEmpty
            ? .empty("Станция не найдена")
            : .loaded
    }

    private func extractStationsForCity(
        from response: AllStationsResponse,
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
                .trimmingCharacters(in: .whitespacesAndNewlines)

            let rawTitle =
                station.popular_title ??
                station.title ??
                station.short_title ??
                ""

            let title = rawTitle
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard !code.isEmpty, !title.isEmpty else { return nil }
            if title.hasPrefix("#") { return nil }

            return StationItem(id: code, title: title, code: code)
        }

        let unique = Array(Set(mapped))
            .sorted { $0.title < $1.title }

        return unique
    }
}
