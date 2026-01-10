import Foundation

struct Story: Identifiable, Equatable {
    let id: Int
    let previewImageName: String
    let pages: [String]
    
    let previewTitle: String
    let previewSubtitle: String
    
    let titles: [String]
    let bodies: [String]
}
