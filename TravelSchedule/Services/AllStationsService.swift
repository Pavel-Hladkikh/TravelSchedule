import OpenAPIRuntime
import OpenAPIURLSession
import Foundation

typealias AllStationsResponse = Components.Schemas.AllStationsResponse

protocol AllStationsServiceProtocol {
    func getAllStations(
        lang: String?,
        format: String
    ) async throws -> AllStationsResponse
}

final class AllStationsService: AllStationsServiceProtocol {
    private let client: Client
    private let apikey: String
    private let decoder = JSONDecoder()

    init(client: Client, apikey: String) {
        self.client = client
        self.apikey = apikey
    }

    func getAllStations(
        lang: String? = nil,
        format: String = "json"
    ) async throws -> AllStationsResponse {
        let response = try await client.getAllStations(
            query: .init(
                apikey: apikey,
                lang: lang,
                format: format
            )
        )

        let responseBody = try response.ok.body.html
        let limit = 50 * 1024 * 1024
        let fullData = try await Data(collecting: responseBody, upTo: limit)
        let allStations = try decoder.decode(AllStationsResponse.self, from: fullData)
        return allStations
    }
}
