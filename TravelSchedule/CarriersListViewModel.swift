import Foundation

@MainActor
final class CarriersListViewModel: ObservableObject {
    
    struct CarrierRow: Identifiable, Hashable, Sendable {
        let id: String
        
        let title: String
        let subtitle: String?
        
        let dateText: String?
        let departText: String?
        let arriveText: String?
        let durationText: String?
        
        let logoURL: URL?
        
        let email: String?
        let phone: String?
        let website: String?
        
        let departMinutes: Int?
        let hasTransfers: Bool
        
        let carrierCode: String?
    }
    
    @Published private(set) var state: LoadingState = .loading
    @Published private(set) var rows: [CarrierRow] = []
    
    private let apiClient: RaspAPIClient
    private let fromCode: String
    private let toCode: String
    
    private var allRows: [CarrierRow] = []
    private var currentTimeSelection: Set<DepartureInterval> = []
    private var currentShowTransfers: Bool? = nil
    
    init(apiClient: RaspAPIClient, fromCode: String, toCode: String) {
        self.apiClient = apiClient
        self.fromCode = fromCode
        self.toCode = toCode
    }
    
    func load() async {
        state = .loading
        
        var retryCount = 0
        
        while !Task.isCancelled {
            do {
                let date = todayYYYYMMDD()
                
                let response = try await apiClient.searchSegments(
                    from: fromCode,
                    to: toCode,
                    date: date,
                    transfers: nil,
                    lang: "ru_RU",
                    format: "json"
                )
                
                if Task.isCancelled { return }
                
                allRows = mapToRows(response)
                applyCurrentFiltersAndPublish()
                return
                
            } catch {
                if Task.isCancelled { return }
                
                allRows = []
                rows = []
                
                if error.isNoInternet {
                    state = .noInternet
                    let delaySec = min(pow(2.0, Double(retryCount)), 10.0)
                    retryCount += 1
                    let ns = UInt64(delaySec * 1_000_000_000)
                    try? await Task.sleep(nanoseconds: ns)
                    continue
                } else {
                    state = .error("Ошибка загрузки")
                    return
                }
            }
        }
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
            }
        }
        
        return result
    }
    
    private func mapToRows(_ response: SearchSegments) -> [CarrierRow] {
        let segments = response.segments ?? []
        var result: [CarrierRow] = []
        result.reserveCapacity(segments.count)
        
        for seg in segments {
            let carrier = seg.thread?.carrier
            
            let carrierTitle = carrier?.title ?? "Перевозчик"
            let logoStr = carrier?.logo ?? ""
            let logoURL = URL(string: logoStr)
            
            let email = carrier?.email?.trimmingCharacters(in: .whitespacesAndNewlines)
            let phone = carrier?.phone?.trimmingCharacters(in: .whitespacesAndNewlines)
            let website = carrier?.url?.trimmingCharacters(in: .whitespacesAndNewlines)
            
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
            
            let carrierCode: String? = {
                if let codeInt = carrier?.code {
                    return String(codeInt)
                }
                return nil
            }()
            
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
                    email: (email?.isEmpty == true) ? nil : email,
                    phone: (phone?.isEmpty == true) ? nil : phone,
                    website: (website?.isEmpty == true) ? nil : website,
                    departMinutes: departMinutes,
                    hasTransfers: hasTransfers,
                    carrierCode: carrierCode
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
}
