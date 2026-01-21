import SwiftUI

enum LoadingState: Equatable {
    case idle
    case loading
    case loaded
    case empty(String)
    case noInternet
    case error(String)
    
    static func == (lhs: LoadingState, rhs: LoadingState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.loading, .loading), (.loaded, .loaded), (.noInternet, .noInternet):
            return true
        case (.empty(let a), .empty(let b)):
            return a == b
        case (.error(let a), .error(let b)):
            return a == b
        default:
            return false
        }
    }
}

struct StateContentView<Content: View>: View {
    let state: LoadingState
    let emptyMessage: String
    @ViewBuilder let content: () -> Content
    
    init(
        state: LoadingState,
        emptyMessage: String = "Ничего не найдено",
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.state = state
        self.emptyMessage = emptyMessage
        self.content = content
    }
    
    var body: some View {
        switch state {
        case .idle:
            Color.clear
            
        case .loading:
            VStack {
                Spacer()
                ProgressView()
                Spacer()
            }
            .frame(maxWidth: .infinity)
            
        case .loaded:
            content()
            
        case .empty:
            VStack {
                Spacer()
                Text(emptyMessage)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)
                Spacer()
            }
            .frame(maxWidth: .infinity)
            
        case .noInternet:
            VStack {
                Spacer()
                ErrorView(image: "internet_err", title: "Нет интернета")
                Spacer()
            }
            .frame(maxWidth: .infinity)
            
        case .error:
            VStack {
                Spacer()
                ErrorView(image: "server_err", title: "Ошибка сервера")
                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
    }
}

extension Error {
    var isNoInternet: Bool {
        let errorDescription = localizedDescription.lowercased()
        let networkPhrases = [
            "internet connection appears to be offline",
            "not connected to the internet",
            "network connection lost",
            "the internet connection appears to be offline",
            "a server with the specified hostname could not be found",
            "could not connect to the server",
            "the network connection was lost",
            "the request timed out"
        ]
        
        for phrase in networkPhrases {
            if errorDescription.contains(phrase) {
                return true
            }
        }
        
        let ns = self as NSError
        
        if ns.domain == NSURLErrorDomain {
            let networkErrorCodes = [
                NSURLErrorNotConnectedToInternet,
                NSURLErrorCannotFindHost,
                NSURLErrorCannotConnectToHost,         
                NSURLErrorNetworkConnectionLost,
                NSURLErrorDNSLookupFailed,
                NSURLErrorResourceUnavailable,
                NSURLErrorDataNotAllowed,
                NSURLErrorTimedOut
            ]
            
            if networkErrorCodes.contains(ns.code) {
                return true
            }
        }
        
        if ns.domain == "kCFErrorDomainCFNetwork" {
            return true
        }
        
        if ns.domain == "NSPOSIXErrorDomain" {
            return true
        }
        
        if let underlying = ns.userInfo[NSUnderlyingErrorKey] as? NSError {
            return underlying.isNoInternet
        }
        
        if let underlying = ns.userInfo["NSUnderlyingError"] as? NSError {
            return underlying.isNoInternet
        }
        
        return false
    }
}
