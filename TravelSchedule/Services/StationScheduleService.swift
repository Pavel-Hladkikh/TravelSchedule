import OpenAPIRuntime
import OpenAPIURLSession

typealias StationScheduleResponse = Components.Schemas.ScheduleResponse

protocol StationScheduleServiceProtocol {
    func getSchedule(station: String, date: String?) async throws -> StationScheduleResponse
}

final class StationScheduleService: StationScheduleServiceProtocol {
    private let client: Client
    private let apikey: String
    
    init(client: Client, apikey: String) {
        self.client = client
        self.apikey = apikey
    }
    
    func getSchedule(station: String, date: String?) async throws -> StationScheduleResponse {
        let response = try await client.getStationSchedule(query: .init(
            apikey: apikey,
            station: station,
            lang: nil,
            format: "json",
            date: date,
            transport_types: nil,
            event: nil,
            direction: nil,
            system: nil,
            result_timezone: nil
        ))
        return try response.ok.body.json
    }
}
