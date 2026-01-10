import Foundation

@MainActor
final class CarrierInfoViewModel: ObservableObject {
    
    struct DataModel: Equatable {
        var title: String
        var logoURL: URL?
        var email: String?
        var phone: String?
        var website: String?
    }
    
    @Published private(set) var state: LoadingState = .loading
    @Published private(set) var data: DataModel = .init(
        title: "Перевозчик",
        logoURL: nil,
        email: nil,
        phone: nil,
        website: nil
    )
    
    private let carrierCode: String?
    private let carrierService: CarrierServiceProtocol
    
    private var loadTask: Task<Void, Never>?
    
    init(
        carrierCode: String?,
        carrierService: CarrierServiceProtocol
    ) {
        self.carrierCode = carrierCode
        self.carrierService = carrierService
    }
    
    deinit {
        loadTask?.cancel()
    }
    
    func load() async {
        loadTask?.cancel()
        
        loadTask = Task {
            guard let carrierCode, !carrierCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                state = .error("Нет кода перевозчика")
                return
            }
            
            state = .loading
            
            do {
                let response = try await carrierService.getCarrierInfo(code: carrierCode)
                guard !Task.isCancelled else { return }
                
                let carrier = response.carriers?.first
                
                let title = carrier?.title?.trimmingCharacters(in: .whitespacesAndNewlines)
                let email = carrier?.email?.trimmingCharacters(in: .whitespacesAndNewlines)
                let phone = carrier?.phone?.trimmingCharacters(in: .whitespacesAndNewlines)
                let website = carrier?.url?.trimmingCharacters(in: .whitespacesAndNewlines)
                let logo = carrier?.logo?.trimmingCharacters(in: .whitespacesAndNewlines)
                
                data.title = (title?.isEmpty == false) ? title! : "Перевозчик"
                data.email = (email?.isEmpty == false) ? email : nil
                data.phone = (phone?.isEmpty == false) ? phone : nil
                data.website = (website?.isEmpty == false) ? website : nil
                data.logoURL = (logo?.isEmpty == false) ? URL(string: logo!) : nil
                
                state = .loaded
                
            } catch {
                guard !Task.isCancelled else { return }
                
                if error.isNoInternet {
                    state = .noInternet
                } else {
                    state = .error("Ошибка загрузки")
                }
            }
        }
        
        await loadTask?.value
    }
}
