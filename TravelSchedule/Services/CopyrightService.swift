import OpenAPIRuntime
import OpenAPIURLSession

typealias CopyrightModel = Components.Schemas.Copyright

protocol CopyrightServiceProtocol {
    func getCopyright() async throws -> CopyrightModel
}

final class CopyrightService: CopyrightServiceProtocol {
    private let client: Client
    private let apikey: String

    init(client: Client, apikey: String) {
        self.client = client
        self.apikey = apikey
    }

    func getCopyright() async throws -> CopyrightModel {
        let response = try await client.getCopyright(
            query: .init(
                apikey: apikey,
                format: "json"
            )
        )

        return try response.ok.body.json
    }
}
