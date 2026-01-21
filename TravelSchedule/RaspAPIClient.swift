import Foundation
import OpenAPIRuntime
import OpenAPIURLSession

actor RaspAPIClient {
    
    enum APIError: Error {
        case responseTooLarge
        case unexpectedStatus(Int)
    }
    
    private let client: Client
    private let apiKey: String
    
    private let maxBodyBytes = 50 * 1024 * 1024
    
    init(
        serverURL: URL = URL(string: "https://api.rasp.yandex-net.ru")!,
        apiKey: String,
        transport: ClientTransport = URLSessionTransport()
    ) {
        self.client = Client(serverURL: serverURL, transport: transport)
        self.apiKey = apiKey
    }
    
    func searchSegments(
        from: String,
        to: String,
        date: String,
        transfers: Bool? = nil,
        lang: String? = "ru_RU",
        format: String? = "json"
    ) async throws -> Components.Schemas.Segments {
        
        let response = try await client.getScheduleBetweenStations(
            query: .init(
                apikey: apiKey,
                from: from,
                to: to,
                format: format,
                lang: lang,
                date: date,
                transfers: transfers
            )
        )
        
        switch response {
        case .ok(let ok):
            return try ok.body.json
            
        case .undocumented(let statusCode, _):
            if statusCode == 404 {
                let data = Data(#"{"segments":[]}"#.utf8)
                return try JSONDecoder().decode(Components.Schemas.Segments.self, from: data)
            }
            throw APIError.unexpectedStatus(statusCode)
        }
    }
    
    func allStations(
        lang: String = "ru_RU",
        format: String = "json"
    ) async throws -> Components.Schemas.AllStationsResponse {
        
        let response = try await client.getAllStations(
            query: .init(
                apikey: apiKey,
                lang: lang,
                format: format
            )
        )
        
        switch response {
        case .ok(let ok):
            let body = try ok.body.html
            
            var data = Data()
            for try await chunk in body {
                data.append(contentsOf: chunk)
                if data.count > maxBodyBytes {
                    throw APIError.responseTooLarge
                }
            }
            
            return try JSONDecoder().decode(Components.Schemas.AllStationsResponse.self, from: data)
            
        case .undocumented(let statusCode, _):
            throw APIError.unexpectedStatus(statusCode)
        }
    }
    
    func carrierInfo(
        code: String,
        system: String? = nil,
        lang: String? = "ru_RU",
        format: String? = "json"
    ) async throws -> Components.Schemas.CarrierResponse {
        
        let response = try await client.getCarrierInfo(
            query: .init(
                apikey: apiKey,
                code: code,
                system: system,
                lang: lang,
                format: format
            )
        )
        
        switch response {
        case .ok(let ok):
            return try ok.body.json
        case .undocumented(let statusCode, _):
            throw APIError.unexpectedStatus(statusCode)
        }
    }
    
    func stationSchedule(
        station: String,
        date: String? = nil,
        transportTypes: String? = nil,
        event: String? = nil,
        lang: String? = "ru_RU",
        format: String? = "json"
    ) async throws -> Components.Schemas.ScheduleResponse {
        
        let response = try await client.getStationSchedule(
            query: .init(
                apikey: apiKey,
                station: station,
                lang: lang,
                format: format,
                date: date,
                transport_types: transportTypes,
                event: event
            )
        )
        
        switch response {
        case .ok(let ok):
            return try ok.body.json
        case .undocumented(let statusCode, _):
            throw APIError.unexpectedStatus(statusCode)
        }
    }
    
    func routeStations(
        uid: String,
        from: String? = nil,
        to: String? = nil,
        date: String? = nil,
        lang: String? = "ru_RU",
        format: String? = "json"
    ) async throws -> Components.Schemas.ThreadStationsResponse {
        
        let response = try await client.getRouteStations(
            query: .init(
                apikey: apiKey,
                uid: uid,
                from: from,
                to: to,
                format: format,
                lang: lang,
                date: date
            )
        )
        
        switch response {
        case .ok(let ok):
            return try ok.body.json
        case .undocumented(let statusCode, _):
            throw APIError.unexpectedStatus(statusCode)
        }
    }
    
    func nearestCity(
        lat: Double,
        lng: Double,
        distance: Int? = nil,
        lang: String? = "ru_RU",
        format: String? = "json"
    ) async throws -> Components.Schemas.NearestCityResponse {
        
        let response = try await client.getNearestCity(
            query: .init(
                apikey: apiKey,
                lat: lat,
                lng: lng,
                distance: distance,
                lang: lang,
                format: format
            )
        )
        
        switch response {
        case .ok(let ok):
            return try ok.body.json
        case .undocumented(let statusCode, _):
            throw APIError.unexpectedStatus(statusCode)
        }
    }
    
    func nearestStations(
        lat: Double,
        lng: Double,
        distance: Int,
        lang: String? = "ru_RU",
        format: String? = "json",
        stationTypes: String? = nil,
        transportTypes: String? = nil,
        offset: Int? = nil,
        limit: Int? = nil
    ) async throws -> Components.Schemas.Stations {
        
        let response = try await client.getNearestStations(
            query: .init(
                apikey: apiKey,
                lat: lat,
                lng: lng,
                distance: distance,
                lang: lang,
                format: format,
                station_types: stationTypes,
                transport_types: transportTypes,
                offset: offset,
                limit: limit
            )
        )
        
        switch response {
        case .ok(let ok):
            return try ok.body.json
        case .undocumented(let statusCode, _):
            throw APIError.unexpectedStatus(statusCode)
        }
    }
    
    func copyright(format: String? = "json") async throws -> Components.Schemas.Copyright {
        
        let response = try await client.getCopyright(
            query: .init(
                apikey: apiKey,
                format: format
            )
        )
        
        switch response {
        case .ok(let ok):
            return try ok.body.json
        case .undocumented(let statusCode, _):
            throw APIError.unexpectedStatus(statusCode)
        }
    }
}

enum RaspAPI {
    static let apiKey = "7828af98-e2dc-45df-95f7-12b6d39376ef"
    static let shared = RaspAPIClient(apiKey: apiKey)
}
