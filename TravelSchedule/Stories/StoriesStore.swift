import SwiftUI

@MainActor
final class StoriesStore: ObservableObject {
    
    @Published private(set) var stories: [Story] = []
    @Published var viewedIDs: Set<Int> = []
    
    init() {
        stories = Self.makeStories()
        viewedIDs = []
    }
    
    func isViewed(_ id: Int) -> Bool {
        viewedIDs.contains(id)
    }
    
    func markViewed(_ id: Int) {
        viewedIDs.insert(id)
    }
    
    private static func makeStories() -> [Story] {
        (1...9).map { i in
            let num = String(format: "%02d", i)
            
            return Story(
                id: i,
                previewImageName: "stories_preview_\(num)",
                pages: ["stories_big_\(num)", "stories_next_\(num)"],
                previewTitle: "Text Text Text\nText Text\nText Text T…",
                previewSubtitle: "",
                titles: [
                    "Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text",
                    "Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text"
                ],
                bodies: [
                    "Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text",
                    "Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text"
                ]
            )
        }
    }
}
