import SwiftUI
import Combine

struct StoriesViewerView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    let stories: [Story]
    let onStoryViewed: (Int) -> Void
    let initialStoryIndex: Int
    
    @State private var currentStoryIndex: Int = 0
    @State private var currentPageIndex: Int = 0
    @State private var pageProgress: CGFloat = 0
    
    private let tick: TimeInterval = 0.05
    private let secondsPerStory: TimeInterval = 10
    private var secondsPerPage: TimeInterval { secondsPerStory / 2 }
    
    @State private var timer = Timer.publish(every: 0.05, on: .main, in: .common)
    @State private var cancellable: Cancellable?
    @State private var hasAppeared = false
    @State private var isInitialSetup = true
    
    init(
        stories: [Story],
        startIndex: Int,
        onStoryViewed: @escaping (Int) -> Void
    ) {
        self.stories = stories
        self.onStoryViewed = onStoryViewed
        self.initialStoryIndex = min(max(startIndex, 0), max(stories.count - 1, 0))
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            TabView(selection: $currentStoryIndex) {
                ForEach(stories.indices, id: \.self) { index in
                    StoryCard(
                        imageName: imageName(for: index),
                        titleText: titleText(for: index),
                        bodyText: bodyText(for: index),
                        pageIndex: index == currentStoryIndex ? currentPageIndex : 0,
                        pageProgress: index == currentStoryIndex ? pageProgress : 0,
                        onClose: { dismiss() }
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()
            .onChange(of: currentStoryIndex) { oldValue, newValue in
                if isInitialSetup {
                    isInitialSetup = false
                    return
                }
                
                if hasAppeared, stories.indices.contains(oldValue), oldValue != newValue {
                    onStoryViewed(stories[oldValue].id)
                }
                currentPageIndex = 0
                pageProgress = 0
                resetTimer()
            }
        }
        .onAppear {
            if !hasAppeared {
                isInitialSetup = (initialStoryIndex != 0)
                
                currentStoryIndex = initialStoryIndex
                currentPageIndex = 0
                pageProgress = 0
                
                resetTimer()
                hasAppeared = true
            } else {
                resetTimer()
            }
        }
        .onDisappear {
            cancellable?.cancel()
        }
        .onReceive(timer) { _ in
            tickTimer()
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onEnded(handleGesture)
        )
    }
    
    private func tickTimer() {
        pageProgress += CGFloat(tick / secondsPerPage)
        if pageProgress >= 1 {
            pageProgress = 0
            next()
        }
    }
    
    private func resetTimer() {
        cancellable?.cancel()
        timer = Timer.publish(every: tick, on: .main, in: .common)
        cancellable = timer.connect()
        pageProgress = 0
    }
    
    private func next() {
        if currentPageIndex < 1 {
            currentPageIndex += 1
            return
        }
        
        onStoryViewed(stories[currentStoryIndex].id)
        
        if currentStoryIndex < stories.count - 1 {
            currentStoryIndex += 1
            currentPageIndex = 0
        } else {
            dismiss()
        }
    }
    
    private func prev() {
        if currentPageIndex > 0 {
            currentPageIndex -= 1
            return
        }
        
        if currentStoryIndex > 0 {
            currentStoryIndex -= 1
            currentPageIndex = 1
        }
    }
    
    private func handleGesture(_ value: DragGesture.Value) {
        let dx = value.translation.width
        let dy = value.translation.height
        
        if dy > 90 {
            dismiss()
            return
        }
        
        if abs(dx) < 10, abs(dy) < 10 {
            value.location.x < UIScreen.main.bounds.width * 0.35 ? prev() : next()
            resetTimer()
        }
    }
    
    private func imageName(for index: Int) -> String {
        let story = stories[index]
        let page = (index == currentStoryIndex) ? currentPageIndex : 0
        return story.pages[safe: page] ?? ""
    }
    
    private func titleText(for index: Int) -> String {
        let story = stories[index]
        let page = (index == currentStoryIndex) ? currentPageIndex : 0
        return story.titles[safe: page] ?? ""
    }
    
    private func bodyText(for index: Int) -> String {
        let story = stories[index]
        let page = (index == currentStoryIndex) ? currentPageIndex : 0
        return story.bodies[safe: page] ?? ""
    }
}

private struct StoryCard: View {
    
    let imageName: String
    let titleText: String
    let bodyText: String
    let pageIndex: Int
    let pageProgress: CGFloat
    let onClose: () -> Void
    
    private let cornerRadius: CGFloat = 28
    
    var body: some View {
        GeometryReader { geo in
            let contentWidth = geo.size.width - 32
            
            ZStack {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                
                VStack {
                    VStack(spacing: 16) {
                        ProgressBarPages(
                            sections: 2,
                            currentIndex: pageIndex,
                            currentProgress: pageProgress,
                            height: 6
                        )
                        
                        HStack {
                            Spacer()
                            CloseCircleButton(action: onClose)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 28)
                    
                    Spacer()
                }
            }
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 16) {
                    
                    Text(titleText)
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .truncationMode(.tail)
                        .multilineTextAlignment(.leading)
                        .frame(width: contentWidth, alignment: .leading)
                    
                    Text(bodyText)
                        .font(.system(size: 20))
                        .foregroundStyle(.white)
                        .lineLimit(3)
                        .truncationMode(.tail)
                        .multilineTextAlignment(.leading)
                        .frame(width: contentWidth, alignment: .leading)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
            .clipShape(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
        }
    }
}

private struct ProgressBarPages: View {
    let sections: Int
    let currentIndex: Int
    let currentProgress: CGFloat
    let height: CGFloat
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<sections, id: \.self) { i in
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white)
                        Capsule()
                            .fill(AppColors.brandBlue)
                            .frame(width: fillWidth(for: i, totalWidth: geo.size.width))
                    }
                }
                .frame(height: height)
            }
        }
    }
    
    private func fillWidth(for index: Int, totalWidth: CGFloat) -> CGFloat {
        if index < currentIndex { return totalWidth }
        if index > currentIndex { return 0 }
        return totalWidth * min(max(currentProgress, 0), 1)
    }
}

private struct CloseCircleButton: View {
    let action: () -> Void
    
    private let strokeColor = Color(
        red: 26.0 / 255.0,
        green: 27.0 / 255.0,
        blue: 34.0 / 255.0
    )
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(Color.black)
                .overlay(Circle().stroke(strokeColor, lineWidth: 1))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
