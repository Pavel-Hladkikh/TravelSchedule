import Foundation

@MainActor
final class MainSearchViewModel: ObservableObject {
    
    @Published var fromText: String = ""
    @Published var toText: String = ""
    
    @Published var fromCode: String = ""
    @Published var toCode: String = ""
    
    var canSearch: Bool {
        !fromCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !toCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    func swapStations() {
        Swift.swap(&fromText, &toText)
        Swift.swap(&fromCode, &toCode)
    }
    
    func setFrom(stationTitle: String, stationCode: String, cityTitle: String) {
        fromText = stationTitle
        fromCode = stationCode
    }
    
    func setTo(stationTitle: String, stationCode: String, cityTitle: String) {
        toText = stationTitle
        toCode = stationCode
    }
    
    func clearFrom() {
        fromText = ""
        fromCode = ""
    }
    
    func clearTo() {
        toText = ""
        toCode = ""
    }
}
