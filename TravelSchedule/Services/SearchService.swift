import OpenAPIRuntime
import OpenAPIURLSession

typealias SearchSegments = Components.Schemas.Segments

protocol SearchServiceProtocol {
    func getSegments(from: String, to: String, date: String?) async throws -> SearchSegments
}

final class SearchService: SearchServiceProtocol {
    private let client: Client
    private let apikey: String

    init(client: Client, apikey: String) {
        self.client = client
        self.apikey = apikey
    }

    func getSegments(from: String, to: String, date: String?) async throws -> SearchSegments {
        let response = try await client.getScheduleBetweenStations(
            query: .init(
                apikey: apikey,
                from: from,
                to: to,
                format: "json",
                lang: nil,
                date: date,
                transport_types: nil,
                offset: nil,
                limit: nil,
                result_timezone: nil,
                transfers: nil
            )
        )

        return try response.ok.body.json
    }
}
