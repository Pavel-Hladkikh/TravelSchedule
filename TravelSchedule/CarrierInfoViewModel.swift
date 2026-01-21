import Foundation

@MainActor
final class CarrierInfoViewModel: ObservableObject {
    
    struct DataModel: Equatable, Sendable {
        var title: String
        var logoURL: URL?
        var email: String?
        var phone: String?
        var website: String?
    }
    
    @Published private(set) var state: LoadingState = .idle
    @Published private(set) var data: DataModel
    
    private let carrierCode: String?
    private let apiClient: RaspAPIClient
    
    init(
        seed: DataModel,
        carrierCode: String?,
        apiClient: RaspAPIClient
    ) {
        self.data = seed
        self.carrierCode = carrierCode
        self.apiClient = apiClient
    }
    
    func load() async {
        let code = (carrierCode ?? "")
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
        guard !code.isEmpty else {
            state = .error("Нет кода перевозчика")
            return
        }
        
        state = .loading
        
        do {
            let response = try await apiClient.carrierInfo(code: code)
            if Task.isCancelled { return }
            
            let carrier = response.carriers?.first
            
            let title = carrier?.title?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            let email = carrier?.email?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            let phone = carrier?.phone?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            let website = carrier?.url?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            let logo = carrier?.logo?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            
            if let title, !title.isEmpty { data.title = title }
            if let email, !email.isEmpty { data.email = email }
            if let phone, !phone.isEmpty { data.phone = phone }
            if let website, !website.isEmpty { data.website = website }
            if let logo, !logo.isEmpty { data.logoURL = URL(string: logo) }
            
            state = .loaded
            
        } catch {
            if Task.isCancelled { return }
            
            if error.isNoInternet {
                state = .noInternet
            } else {
                state = .error("Ошибка загрузки")
            }
        }
    }
}
