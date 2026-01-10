import SwiftUI

struct StoriesRowView: View {
    
    @StateObject private var store = StoriesStore()
    
    private struct SelectedStory: Identifiable {
        let id: Int
        let index: Int
    }
    
    @State private var selected: SelectedStory? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            
            Color.clear
                .frame(height: 24)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(store.stories.enumerated()), id: \.element.id) { index, story in
                        StoryPreviewCell(
                            imageName: story.previewImageName,
                            isViewed: store.isViewed(story.id)
                        )
                        .frame(width: 92, height: 140)
                        .onTapGesture {
                            selected = SelectedStory(id: story.id, index: index)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            
            Color.clear
                .frame(height: 44)
        }
        .fullScreenCover(item: $selected) { item in
            StoriesViewerView(
                stories: store.stories,
                startIndex: item.index,
                onStoryViewed: { id in
                    store.markViewed(id)
                }
            )
        }
    }
}

private struct StoryPreviewCell: View {
    let imageName: String
    let isViewed: Bool
    
    private let previewText =
    "Text Text Text Text Text Text Text Text Text\n" +
    "Text Text Text Text Text Text Text Text Text\n" +
    "Text Text Text Text Text Text Text Text Text"
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 92, height: 140)
                .clipped()
                .opacity(isViewed ? 0.5 : 1)
            
            Text(previewText)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(.white)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 8)
                .padding(.bottom, 12)   
                .clipped()
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(isViewed ? Color.clear : AppColors.brandBlue, lineWidth: 4)
        }
        .contentShape(Rectangle())
    }
}
