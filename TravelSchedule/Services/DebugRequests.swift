import OpenAPIRuntime
import OpenAPIURLSession

private let apiKey = "7828af98-e2dc-45df-95f7-12b6d39376ef"

// 1. Ближайшие станции
func testFetchStations() {
    Task {
        do {
            let client = Client(
                serverURL: try Servers.Server1.url(),
                transport: URLSessionTransport()
            )
            let service = NearestStationsService(client: client, apikey: apiKey)
            
            print("Fetching nearest stations...")
            let stations = try await service.getNearestStations(
                lat: 59.864177,
                lng: 30.319163,
                distance: 50
            )
            print("Nearest stations success:", stations)
        } catch {
            print("Nearest stations error:", error)
        }
    }
}

// 2. Рейсы между станциями
func testFetchSegments() {
    Task {
        do {
            let client = Client(
                serverURL: try Servers.Server1.url(),
                transport: URLSessionTransport()
            )
            let service = SearchService(client: client, apikey: apiKey)
            
            print("Fetching segments...")
            let segments = try await service.getSegments(
                from: "s9602494",
                to: "s9602496",
                date: nil
            )
            print("Segments success:", segments)
        } catch {
            print("Segments error:", error)
        }
    }
}

// 3. Расписание по станции
func testFetchStationSchedule() {
    Task {
        do {
            let client = Client(
                serverURL: try Servers.Server1.url(),
                transport: URLSessionTransport()
            )
            let service = StationScheduleService(client: client, apikey: apiKey)
            
            print("Fetching station schedule...")
            let schedule = try await service.getSchedule(
                station: "s9602494",
                date: nil
            )
            print("Station schedule success:", schedule)
        } catch {
            print("Station schedule error:", error)
        }
    }
}

// 4. Список станций следования
func testFetchRouteStations() {
    Task {
        do {
            let client = Client(
                serverURL: try Servers.Server1.url(),
                transport: URLSessionTransport()
            )
            let service = ThreadService(client: client, apikey: apiKey)
            
            print("Fetching route stations...")
            let route = try await service.getRouteStations(uid: "some_uid")
            print("Route stations success:", route)
        } catch {
            print("Route stations error:", error)
        }
    }
}

// 5. Ближайший город
func testFetchNearestCity() {
    Task {
        do {
            let client = Client(
                serverURL: try Servers.Server1.url(),
                transport: URLSessionTransport()
            )
            let service = NearestSettlementService(client: client, apikey: apiKey)
            
            print("Fetching nearest city...")
            let city = try await service.getNearestCity(
                lat: 55.75222,
                lng: 37.61556,
                distance: 50
            )
            print("Nearest city success:", city)
        } catch {
            print("Nearest city error:", error)
        }
    }
}

// 6. Перевозчик
func testFetchCarrier() {
    Task {
        do {
            let client = Client(
                serverURL: try Servers.Server1.url(),
                transport: URLSessionTransport()
            )
            let service = CarrierService(client: client, apikey: apiKey)
            
            print("Fetching carrier info...")
            let carrier = try await service.getCarrierInfo(code: "SU")
            print("Carrier info success:", carrier)
        } catch {
            print("Carrier info error:", error)
        }
    }
}

// 7. Все станции
func testFetchAllStations() {
    Task {
        do {
            let client = Client(
                serverURL: try Servers.Server1.url(),
                transport: URLSessionTransport()
            )
            let service = AllStationsService(client: client, apikey: apiKey)
            
            print("Fetching all stations...")
            let allStations = try await service.getAllStations()
            print("All stations success:", allStations)
        } catch {
            print("All stations error:", error)
        }
    }
}

// 8. Копирайт
func testFetchCopyright() {
    Task {
        do {
            let client = Client(
                serverURL: try Servers.Server1.url(),
                transport: URLSessionTransport()
            )
            let service = CopyrightService(client: client, apikey: apiKey)
            
            print("Fetching copyright...")
            let info = try await service.getCopyright()
            print("Copyright success:", info)
        } catch {
            print("Copyright error:", error)
        }
    }
}
