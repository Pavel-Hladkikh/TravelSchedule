import Foundation

@MainActor
final class CarriersListViewModel: ObservableObject {

    struct CarrierRow: Identifiable, Hashable {
        let id: String
        let title: String
        let subtitle: String?
        let dateText: String?
        let departText: String?
        let arriveText: String?
        let durationText: String?
        let logoURL: URL?
        let departMinutes: Int?
        let hasTransfers: Bool
    }

    @Published private(set) var state: LoadingState = .loading
    @Published private(set) var rows: [CarrierRow] = []

    private let searchService: SearchServiceProtocol
    private let fromCode: String
    private let toCode: String

    private var allRows: [CarrierRow] = []
    private var currentTimeSelection: Set<DepartureInterval> = []
    private var currentShowTransfers: Bool? = nil

    private var loadTask: Task<Void, Never>?
    private var retryTimer: Timer?
    private var retryCount = 0

    init(searchService: SearchServiceProtocol, fromCode: String, toCode: String) {
        self.searchService = searchService
        self.fromCode = fromCode
        self.toCode = toCode
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
                let date = todayYYYYMMDD()
                let response = try await searchService.getSegments(
                    from: fromCode,
                    to: toCode,
                    date: date
                )

                guard !Task.isCancelled else { return }

                allRows = mapToRows(response)
                retryCount = 0
                applyCurrentFiltersAndPublish()

            } catch {
                guard !Task.isCancelled else { return }

                allRows = []
                rows = []

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

    func applyFilters(timeSelection: Set<DepartureInterval>, showTransfers: Bool?) {
        currentTimeSelection = timeSelection
        currentShowTransfers = showTransfers
        applyCurrentFiltersAndPublish()
    }

    private func applyCurrentFiltersAndPublish() {
        let filtered = filterRows(allRows)
        rows = filtered

        if filtered.isEmpty {
            state = .empty("Вариантов нет")
        } else {
            state = .loaded
        }
    }

    private func filterRows(_ input: [CarrierRow]) -> [CarrierRow] {
        var result = input

        if !currentTimeSelection.isEmpty {
            result = result.filter { row in
                guard let m = row.departMinutes else { return false }
                return currentTimeSelection.contains { $0.range.contains(m) }
            }
        }

        if let showTransfers = currentShowTransfers {
            if showTransfers == false {
                result = result.filter { !$0.hasTransfers }
            } else {
                
            }
        }

        return result
    }

    private func mapToRows(_ response: SearchSegments) -> [CarrierRow] {
        let segments = response.segments ?? []
        var result: [CarrierRow] = []
        result.reserveCapacity(segments.count)

        for seg in segments {
            let carrierTitle = seg.thread?.carrier?.title ?? "Перевозчик"
            let logoStr = seg.thread?.carrier?.logo ?? ""
            let logoURL = URL(string: logoStr)

            let departText = timeHHMM(seg.departure)
            let arriveText = timeHHMM(seg.arrival)
            let dateText = dateRu(seg.departure)

            let durationText: String?
            if let dur = seg.duration {
                durationText = durationHuman(seconds: dur)
            } else {
                durationText = nil
            }

            let threadTitle = seg.thread?.title ?? ""
            let parts = threadTitle.components(separatedBy: " — ")
            let hasTransfers = parts.count > 2

            let subtitle: String? = {
                guard hasTransfers, parts.count > 1 else { return nil }
                return "С пересадкой в \(parts[1])"
            }()

            let uid = seg.thread?.uid ?? UUID().uuidString
            let depKey = seg.departure != nil
                ? String(seg.departure!.timeIntervalSince1970)
                : UUID().uuidString
            let id = uid + "_" + depKey

            let departMinutes = seg.departure.map { minutesFromMidnight($0) }

            result.append(
                CarrierRow(
                    id: id,
                    title: carrierTitle,
                    subtitle: subtitle,
                    dateText: dateText,
                    departText: departText,
                    arriveText: arriveText,
                    durationText: durationText,
                    logoURL: logoURL,
                    departMinutes: departMinutes,
                    hasTransfers: hasTransfers
                )
            )
        }

        return result
    }

    private func minutesFromMidnight(_ date: Date) -> Int {
        let cal = Calendar.current
        let h = cal.component(.hour, from: date)
        let m = cal.component(.minute, from: date)
        return h * 60 + m
    }

    private func todayYYYYMMDD() -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }

    private func timeHHMM(_ date: Date?) -> String? {
        guard let d = date else { return nil }
        let f = DateFormatter()
        f.locale = Locale(identifier: "ru_RU")
        f.dateFormat = "HH:mm"
        return f.string(from: d)
    }

    private func dateRu(_ date: Date?) -> String? {
        guard let d = date else { return nil }
        let f = DateFormatter()
        f.locale = Locale(identifier: "ru_RU")
        f.dateFormat = "d MMMM"
        return f.string(from: d)
    }

    private func durationHuman(seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        if h > 0 && m > 0 { return "\(h) ч \(m) м" }
        if h > 0 { return "\(h) ч" }
        return "\(m) м"
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
}
